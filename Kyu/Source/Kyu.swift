//
//  Kyu.swift
//  Kyu
//
//  Created by Red Davis on 08/11/2020.
//

import Foundation
import os.log


public final class Kyu<T> where T: Job
{
    // Public
    
    /// The root directory that Kyu uses to store jobs.
    public let url: URL
    
    /// The number of pending jobs.
    public var numberOfPendingJobs: Int { self.pendingJobs().count }
    
    /// The number of failed jobs.
    public var numberOfFailedJobs: Int { self.failedJobs().count }
    
    /// The number of completed jobs.
    public var numberOfCompletedJobs: Int { self.completedJobs().count }
    
    // Private
    private let logger: Logger
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    
    /// Indicates whether Kyu is processing a job.
    private var isProcessing = false {
        didSet
        {
            if !self.isProcessing { self.processNextJob() }
        }
    }
    
    private let jobProcessingDispatchQueue: DispatchQueue
    private let jobDirectoryObserverDispatchQueue: DispatchQueue
    private var jobDirectoryObserver: DispatchSourceFileSystemObject!
    
    private let pendingDirectory: Directory
    private let completedDirectory: Directory
    private let failedDirectory: Directory
    private let tempDirectory: Directory
    
    private let tempDirectoryName = "temp"
    private let pendingDirectoryName = "pending"
    private let completedDirectoryName = "completed"
    private let failedDirectoryName = "failed"
    
    // MARK: Initialization
    
    /// Initialize a new `Kyu` instance.
    /// - Parameters:
    ///   - url: The root directory that Kyu uses to store jobs.
    ///   - logLevel: The level of logging required. Defaults to `.fault`.
    /// - Throws:
    ///   - `Directory.SetupError.fileExistsInDirectoryURL(URL)`
    public required init(url: URL, logLevel: Logger.LogLevel = .fault) throws
    {
        self.url = url
        self.pendingDirectory = Directory(url: url.appendingPathComponent(self.pendingDirectoryName, isDirectory: true))
        self.completedDirectory = Directory(url: url.appendingPathComponent(self.completedDirectoryName, isDirectory: true))
        self.failedDirectory = Directory(url: url.appendingPathComponent(self.failedDirectoryName, isDirectory: true))
        self.tempDirectory = Directory(url: url.appendingPathComponent(self.tempDirectoryName, isDirectory: true))
        
        self.jobProcessingDispatchQueue = DispatchQueue(label: "com.reddavis.Kyu.jobProcessingDispatchQueue.\(UUID())", qos: .utility)
        self.jobDirectoryObserverDispatchQueue = DispatchQueue(label: "com.reddavis.Kyu.jobDirectoryObserverDispatchQueue.\(UUID())", qos: .background)
        
        self.logger = Logger(subsystem: "com.reddavis.kyu", category: "Kyu[\(url.absoluteString)]")
        self.logger.logLevel = logLevel
        
        try self.setup()
    }
    
    // MARK: Setup
    
    private func setup() throws
    {
        try self.pendingDirectory.setup()
        try self.completedDirectory.setup()
        try self.failedDirectory.setup()
        try self.tempDirectory.setup()
        self.setupPendingDirectoryObserver()
    }
    
    private func setupPendingDirectoryObserver()
    {
        let fileDesciptor = open(self.pendingDirectory.url.path, O_EVTONLY)
        self.jobDirectoryObserver = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDesciptor, eventMask: .write, queue: self.jobDirectoryObserverDispatchQueue)
        self.jobDirectoryObserver.setEventHandler { [weak self] in self?.processNextJob() }
        self.jobDirectoryObserver.resume()
    }
    
    // MARK: Jobs
    
    private func processNextJob()
    {
        self.jobProcessingDispatchQueue.async {
            guard !self.isProcessing,
                  let job = self.nextExecutablePendingJob() else { return }
            self.isProcessing = true
            
            job.execute { result in
                defer { self.isProcessing = false }
                
                switch result
                {
                case .success:
                    self.move(job: job, from: self.pendingDirectory, to: self.completedDirectory)
                case .failure where job.numberOfRetries >= job.maximumNumberOfRetries:
                    self.move(job: job, from: self.pendingDirectory, to: self.failedDirectory)
                case .failure:
                    do
                    {
                        var job = job
                        job.incrementRetryCount()
                        
                        let dataURL = self.pendingDirectory.payloadURL(for: job)
                        let data = try self.encoder.encode(job)
                        try data.write(to: dataURL)
                    }
                    catch
                    {
                        self.logger.fault("Failed to increment job (\(job.id)) retry count. Error: \(error)")
                    }
                }
            }
        }
    }
    
    private func delete(job: T) throws
    {
        try self.fileManager.removeItem(at: self.pendingDirectory.url(for: job))
    }
    
    private func move(job: T, from source: Directory, to destination: Directory)
    {
        do
        {
            try self.fileManager.moveItem(at: source.url(for: job), to: destination.url(for: job))
        }
        catch
        {
            self.logger.fault("Failed to move job (\(job.id)). From \(source.url(for: job)) To \(destination.url(for: job))")
        }
    }
    
    private func nextExecutablePendingJob() -> T?
    {
        return self.pendingJobs()
            .filter { $0.isExecutable }
            .sorted { $0.executionDate < $1.executionDate }
            .first
    }
    
    private func pendingJobs() -> [T]
    {
        guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.pendingDirectory.url.path) else { return [] }
        let decoder = JSONDecoder()
        
        return directoryNames
            .map { self.pendingDirectory.payloadURL(for: $0) }
            .compactMap {
                do
                {
                    let data = try Data(contentsOf: $0)
                    return try decoder.decode(T.self, from: data)
                }
                catch { return nil }
            }
    }
    
    private func failedJobs() -> [T]
    {
        guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.failedDirectory.url.path) else { return [] }
        let decoder = JSONDecoder()
        
        return directoryNames
            .map { self.failedDirectory.payloadURL(for: $0) }
            .compactMap {
                do
                {
                    let data = try Data(contentsOf: $0)
                    return try decoder.decode(T.self, from: data)
                }
                catch { return nil }
            }
    }
    
    private func completedJobs() -> [T]
    {
        guard let directoryNames = try? self.fileManager.contentsOfDirectory(atPath: self.completedDirectory.url.path) else { return [] }
        let decoder = JSONDecoder()
        
        return directoryNames
            .map { self.completedDirectory.payloadURL(for: $0) }
            .compactMap {
                do
                {
                    let data = try Data(contentsOf: $0)
                    return try decoder.decode(T.self, from: data)
                }
                catch { return nil }
            }
    }
    
    // MARK: API
    
    /// Schedules a job for execution.
    /// - Parameter job: A `Job` instance.
    /// - Throws:
    ///   - `Kyu.JobError.jobAlreadyExists`
    ///   - `Kyu.JobError.failedAddingJob(reason: Error)`
    public func add(job: T) throws
    {
        do
        {
            let data = try self.encoder.encode(job)
            let tempJobDirectoryURL = self.tempDirectory.url(for: job)
            let pendingDirectoryURL = self.pendingDirectory.url(for: job)
            
            guard !self.fileManager.fileExists(atPath: pendingDirectoryURL.path) else { throw JobError.jobAlreadyExists }
            
            // Create temp job directory
            try self.fileManager.createDirectory(at: tempJobDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            
            // Write data to disk
            let payloadURL = self.tempDirectory.payloadURL(for: job)
            try data.write(to: payloadURL)
            
            // Move temp job directory to pending directory
            try self.fileManager.moveItem(at: tempJobDirectoryURL, to: pendingDirectoryURL)
        }
        catch
        {
            throw JobError.failedAddingJob(reason: error)
        }
    }
}



// MARK: Job error

public extension Kyu
{
    enum JobError: Error
    {
        /// Failed adding a job to a Kyu.
        case failedAddingJob(reason: Error)
        
        /// A job with the same `id` already exists.
        case jobAlreadyExists
    }
}
