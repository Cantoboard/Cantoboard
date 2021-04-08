//
//  EnglishDictionary.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/23/21.
//

import Foundation

extension EnglishDictionary {
    private static let dictionaryDirName = "Dictionary"
    
    public convenience init(locale: String) {
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dictsPath = documentsDirectory.appendingPathComponent("\(Self.dictionaryDirName)", isDirectory: false).path
        
        Self.installDictionariesIfNeeded(dstPath: dictsPath)
        
        self.init(dictsPath + "/\(locale).db")
    }
    
    private static func installDictionariesIfNeeded(dstPath: String) {
        guard let resourcePath = Bundle.init(for: Self.self).resourcePath else {
            fatalError("Bundle.main.resourcePath is nil.")
        }
        
        let srcDictionariesPath = resourcePath + "/\(dictionaryDirName)"
        if isDstFileOutdated(srcPath: srcDictionariesPath + "/generated", dstPath: dstPath + "/generated") {
            NSLog("English Dictionary is outdated. Reinstalling...")
            try? FileManager.default.removeItem(atPath: dstPath)
        } else {
            NSLog("English Dictionary is up to date.")
        }
        
        let dictsImportedPath = dstPath + "/imported"
        if !FileManager.default.fileExists(atPath: dictsImportedPath) {
            try? FileManager.default.removeItem(atPath: dstPath)
            NSLog("Installing English Dictionary from \(srcDictionariesPath) -> \(dstPath)")
            try! FileManager.default.copyItem(atPath: srcDictionariesPath, toPath: dstPath)
            FileManager.default.createFile(atPath: dictsImportedPath, contents: nil, attributes: nil)
        }
    }
    
    private static func isDstFileOutdated(srcPath: String, dstPath: String) -> Bool {
        let srcModifiedDate = getModifiedDate(atPath: srcPath)
        let dstModifiedDate = getModifiedDate(atPath: dstPath)
        
        if dstModifiedDate == nil || srcModifiedDate == nil {
            return true
        }
        return dstModifiedDate! < srcModifiedDate!
    }
    
    private static func getModifiedDate(atPath: String) -> Date? {
        let fileAttributes = try? FileManager.default.attributesOfItem(atPath: atPath)
        let fileModifiedDate = fileAttributes?[FileAttributeKey.modificationDate] as? NSDate as Date?
        return fileModifiedDate
    }
    
    public static func createDb(locale: String) {
        guard let resourcePath = Bundle.init(for: Self.self).resourcePath else {
            fatalError("Bundle.main.resourcePath is nil.")
        }
        let dictTextPath = resourcePath + "/\(dictionaryDirName)/\(locale).txt"
        let commonDictPath = resourcePath + "/\(dictionaryDirName)/common.txt"
        
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dictDbPath = documentsDirectory.appendingPathComponent("\(dictionaryDirName)-build/\(locale).db", isDirectory: false).path
        
        try? FileManager.default.removeItem(atPath: dictDbPath)
        Self.createDb([dictTextPath, commonDictPath], dbPath: dictDbPath)
    }
}
