//
//  Directory.swift
//  Kyu
//
//  Created by Red Davis on 23/11/2020.
//

import Foundation


struct Directory
{
    // Internal
    let url: URL
    
    // Private
    private let fileManager = FileManager.default
    private let jobFileName = "job"
    
    // MARK: API
    
    func url(for job: Job) -> URL { self.url.appendingPathComponent(job.id.uuidString) }
    func payloadURL(for job: Job) -> URL { self.url(for: job).appendingPathComponent(self.jobFileName) }
    func payloadURL(for jobID: String) -> URL { self.url.appendingPathComponent(jobID).appendingPathComponent(self.jobFileName) }
    
    func setup() throws
    {
        var isDirectory = ObjCBool(false)
        let exists = self.fileManager.fileExists(atPath: self.url.path, isDirectory: &isDirectory)
        
        // All good - directory already exists.
        if isDirectory.boolValue && exists { return }
        
        // A file already exists where we want to create our directory.
        else if !isDirectory.boolValue && exists { throw SetupError.fileExistsInDirectoryURL(self.url) }
        
        // Create directory
        try self.fileManager.createDirectory(at: self.url, withIntermediateDirectories: true, attributes: nil)
    }
}



// MARK: Initialization error

extension Directory
{
    enum SetupError: Error
    {
        /// Unable to create directory.
        /// A file already exists at the provided location.
        case fileExistsInDirectoryURL(URL)
    }
}
