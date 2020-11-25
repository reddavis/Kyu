//
//  AppendNewLineJob.swift
//  KyuTests
//
//  Created by Red Davis on 19/11/2020.
//

import Foundation
@testable import Kyu


final class AppendNewLineJob: Job
{
    // Internal
    let id: UUID
    var numberOfRetries = 0
    var retryCooldown = 0.0
    var maximumNumberOfRetries: Int
    var executionDate = Date()
    let fileURL: URL
    let numberOfTimesToFail: Int
    
    let string: String
    let failureString: String
    
    // MARK: Initialization
    
    init(fileURL: URL, string: String, failureString: String, numberOfTimesToFail: Int = 0, maximumNumberOfRetries: Int = 5)
    {
        self.id = UUID()
        self.fileURL = fileURL
        self.string = string
        self.failureString = failureString
        self.numberOfTimesToFail = numberOfTimesToFail
        self.maximumNumberOfRetries = maximumNumberOfRetries
    }
    
    // MARK: Job
    
    func execute(onComplete: @escaping (Result<Void, Error>) -> Void)
    {
        do
        {
            let fileHandle = try FileHandle(forWritingTo: self.fileURL)
            try fileHandle.seekToEnd()
            
            let result: Result<Void, Error>
            if self.numberOfRetries >= self.numberOfTimesToFail
            {
                fileHandle.write("\(self.string)\n".data(using: .utf8)!)
                result = .success(Void())
            }
            else
            {
                fileHandle.write("\(self.failureString)\n".data(using: .utf8)!)
                result = .failure(ExecutionError.failureForced)
            }
            
            fileHandle.closeFile()
            onComplete(result)
        }
        catch
        {
            onComplete(.failure(error))
        }
    }
}



// MARK: Error

extension AppendNewLineJob
{
    enum ExecutionError: Error
    {
        case failureForced
    }
}
