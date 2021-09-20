//
//  Logging.swift
//  CantoboardFramework
//
//  Created by Alex Man on 5/7/21.
//

import Foundation

import CocoaLumberjackSwift

private class LogFormatter: NSObject, DDLogFormatter {
    let dateFormatter: DateFormatter

    override init() {
        dateFormatter = DateFormatter()
        dateFormatter.formatterBehavior = .behavior10_4
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"

        super.init()
    }
    
    func format(message logMessage: DDLogMessage) -> String? {
        let dateAndTime = dateFormatter.string(from: logMessage.timestamp)
        return "\(dateAndTime) [\(logMessage.fileName):\(logMessage.line)]: \(logMessage.message)"
    }
}

func initLogger() -> Bool {
    DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

    let fileLogger: DDFileLogger = DDFileLogger() // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7
    fileLogger.logFormatter = LogFormatter()
    DDLog.add(fileLogger)

    DDASLLogCapture.start()

    return true
}
