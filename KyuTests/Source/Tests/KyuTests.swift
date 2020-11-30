//
//  KyuTests.swift
//  KyuTests
//
//  Created by Red Davis on 08/11/2020.
//

import XCTest
@testable import Kyu


final class KyuTests: XCTestCase
{
    // Private
    private var kyuDirectory: URL!
    private var fileURL: URL!
    
    // MARK: Setup
    
    override func setUpWithError() throws
    {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        self.kyuDirectory = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        self.fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        FileManager.default.createFile(atPath: self.fileURL.path, contents: nil, attributes: nil)
    }

    override func tearDownWithError() throws
    {
        try FileManager.default.removeItem(at: self.fileURL)
    }
    
    // MARK: Tests

    func testExecutingJobs() throws
    {
        let strings = (0...3).map { String($0) }
        let jobs = strings.map { AppendNewLineJob(fileURL: self.fileURL, string: $0, failureString: "failed\($0)") }
        
        let kyu = try Kyu<AppendNewLineJob>(url: self.kyuDirectory)
        
        // Add jobs
        try jobs.forEach {
            XCTAssertNoThrow(try kyu.add(job: $0))
        }
        
        self.expectToEventually(kyu.numberOfPendingJobs == 0, timeout: 5.0)
        
        let fileData = try Data(contentsOf: self.fileURL)
        let fileText = String(data: fileData, encoding: .utf8)
        XCTAssertNotNil(fileText)
        
        let lines = fileText!.split(separator: "\n")
        XCTAssertEqual(lines.count, strings.count)
        
        // Assert jobs gets moved to completed directory
        XCTAssertEqual(kyu.numberOfCompletedJobs, strings.count)
    }
    
    func testOnWillExecuteJobHook() throws
    {
        let originalString = UUID().uuidString
        let updatedString = UUID().uuidString
        let job = AppendNewLineJob(fileURL: self.fileURL, string: originalString, failureString: originalString)
        
        let kyu = try Kyu<AppendNewLineJob>(url: self.kyuDirectory)
        kyu.onWillExecuteJob = { job in
            job.string = updatedString
        }
        
        // Add job
        try kyu.add(job: job)
        
        self.expectToEventually(kyu.numberOfPendingJobs == 0, timeout: 5.0)
        
        let fileData = try Data(contentsOf: self.fileURL)
        let fileText = String(data: fileData, encoding: .utf8)
        
        XCTAssertNotNil(fileText)
        XCTAssertEqual(fileText!.trimmingCharacters(in: .whitespacesAndNewlines), updatedString)
    }
    
    func testRetryingJobExecution() throws
    {
        let string = UUID().uuidString
        let failureString = UUID().uuidString
        let job = AppendNewLineJob(fileURL: self.fileURL, string: string, failureString: failureString, numberOfTimesToFail: 3)
        
        let kyu = try Kyu<AppendNewLineJob>(url: self.kyuDirectory)
        XCTAssertNoThrow(try kyu.add(job: job))
        
        self.expectToEventually(kyu.numberOfPendingJobs == 0, timeout: 5.0)
        
        let fileData = try Data(contentsOf: self.fileURL)
        let fileText = String(data: fileData, encoding: .utf8)
        XCTAssertNotNil(fileText)
        
        let lines = fileText!.split(separator: "\n").map { String($0) }
        XCTAssertEqual(lines.count, 4)
        XCTAssertEqual(lines[0], failureString)
        XCTAssertEqual(lines[1], failureString)
        XCTAssertEqual(lines[2], failureString)
        XCTAssertEqual(lines[3], string)
        
        // Assert job gets moved to completed directory
        XCTAssertEqual(kyu.numberOfCompletedJobs, 1)
    }
    
    func testRetryingJobsStopAfterMaxNumberOfRetries() throws
    {
        let string = UUID().uuidString
        let failureString = UUID().uuidString
        let job = AppendNewLineJob(fileURL: self.fileURL, string: string, failureString: failureString, numberOfTimesToFail: 10, maximumNumberOfRetries: 2)
        
        let kyu = try Kyu<AppendNewLineJob>(url: self.kyuDirectory)
        XCTAssertNoThrow(try kyu.add(job: job))
        
        self.expectToEventually(kyu.numberOfPendingJobs == 0, timeout: 5.0)
        
        let fileData = try Data(contentsOf: self.fileURL)
        let fileText = String(data: fileData, encoding: .utf8)
        XCTAssertNotNil(fileText)
        
        let lines = fileText!.split(separator: "\n").map { String($0) }
        XCTAssertEqual(lines.count, 3) // First try + 2 reties
        XCTAssertEqual(lines[0], failureString)
        XCTAssertEqual(lines[1], failureString)
        
        // Assert job gets moved to failed directory
        XCTAssertEqual(kyu.numberOfFailedJobs, 1)
    }
}
