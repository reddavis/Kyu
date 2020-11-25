//
//  Logger.swift
//  Red Davis
//
//  Created by Red Davis on 01/08/2019.
//  Copyright © 2019 Red Davis. All rights reserved.
//

import Foundation
import os.log


public final class Logger
{
    // Public
    public var logLevel: LogLevel = .info
    
    // Private
    private let log: OSLog
    
    // MARK: Initialziation
    
    required init(subsystem: String, category: String)
    {
        self.log = OSLog(subsystem: subsystem, category: category)
    }
    
    // MARK: API
    
    public func info(_ message: String)
    {
        self.log("ℹ️ \(message)", level: .info)
    }
    
    public func debug(_ message: String)
    {
        self.log("🔎 \(message)", level: .debug)
    }
    
    public func error(_ message: String)
    {
        self.log("⚠️ \(message)", level: .error)
    }

    public func fault(_ message: String)
    {
        self.log("🔥 \(message)", level: .fault)
    }
    
    // MARK: Log
    
    private func log(_ message: String, level: LogLevel)
    {
        guard level >= self.logLevel,
              let type = level.logType else { return }
        os_log("%@", log: self.log, type: type, message)
    }
}



// MARK: Log level

public extension Logger
{
    enum LogLevel: Int
    {
        case info
        case debug
        case error
        case fault
        case off
        
        var logType: OSLogType? {
            switch self
            {
            case .info:
                return .info
            case .debug:
                return .debug
            case .error:
                return .error
            case .fault:
                return .fault
            case .off:
                return nil
            }
        }
    }
}

// MARK: Comparable

extension Logger.LogLevel: Comparable
{
    public static func <(lhs: Logger.LogLevel, rhs: Logger.LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}
