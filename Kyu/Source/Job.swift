//
//  Job.swift
//  Kyu
//
//  Created by Red Davis on 08/11/2020.
//

import Foundation


public protocol Job: Codable
{
    /// A unique identifier for the job.
    var id: UUID { get }
    
    /// The number of times `Kyu` has retried executing the job.
    var numberOfRetries: Int { get set }
    
    /// The maximum number of times the job should be retried.
    var maximumNumberOfRetries: Int { get }
    
    /// The `Date` that the job should be executed after.
    var executionDate: Date { get set }
    
    /// A `Bool` to indicate whether the job is executable.
    var isExecutable: Bool { get }
    
    /// The `TimeInterval` until the job should be retried.
    var retryCooldown: TimeInterval { get }
    
    /// Execute the job.
    /// - Parameter onComplete: A closure to be called when execution is complete.
    func execute(onComplete: @escaping (_ result: Result<Void, Error>) -> Void)
    
    /// Increment the `numberOfRetries` and `executionDate`.
    mutating func incrementRetryCount()
}

// MARK: Default implementation

public extension Job
{
    var isExecutable: Bool { self.executionDate <= Date() }
    
    /// Taken from [Sidekiq](https://github.com/mperham/sidekiq/wiki/Error-Handling#automatic-job-retry).
    /// An exponential backoff.
    /// It will perform 25 retries over approximately 21 days.
    var retryCooldown: TimeInterval {
        let numberOfRetries = Double(self.numberOfRetries)
        return pow(numberOfRetries, 4.0) + 15.0 + (Double.random(in: 0.0...30.0) * (numberOfRetries + 1.0))
    }
    
    mutating func incrementRetryCount()
    {
        self.executionDate = Date(timeIntervalSinceNow: self.retryCooldown)
        self.numberOfRetries += 1
    }
}
