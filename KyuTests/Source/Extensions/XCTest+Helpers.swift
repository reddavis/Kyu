//
//  XCTest.swift
//  KyuTests
//
//  Created by Red Davis on 19/11/2020.
//

import XCTest


extension XCTest
{
    // Thanks to: https://www.vadimbulavin.com/swift-asynchronous-unit-testing-with-busy-assertion-pattern/
    func expectToEventually(_ test: @autoclosure () -> Bool, timeout: TimeInterval = 1.0, message: String = "")
    {
        let runLoop = RunLoop.current
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat
        {
            if test()
            {
                return
            }
            
            runLoop.run(until: Date(timeIntervalSinceNow: 0.01))
        } while Date().compare(timeoutDate) == .orderedAscending
        
        XCTFail(message)
    }
}
