//
//  DirectoryTests.swift
//  KyuTests
//
//  Created by Red Davis on 24/11/2020.
//

import XCTest
@testable import Kyu


final class DirectoryTests: XCTestCase
{
    // Private
    private var url: URL!
    
    // MARK: Setup
    
    override func setUpWithError() throws
    {
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        self.url = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws
    {
        try FileManager.default.removeItem(at: self.url)
    }
    
    // MARK: Tests

    func testSetup() throws
    {
        let directory = Directory(url: self.url)
        XCTAssertNoThrow(try directory.setup())
        
        var isDirectory = ObjCBool(false)
        XCTAssertTrue(FileManager.default.fileExists(atPath: self.url.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }
}
