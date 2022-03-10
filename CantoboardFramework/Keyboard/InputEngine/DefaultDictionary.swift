//
//  EnglishDictionary.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/23/21.
//

import Foundation

import CocoaLumberjackSwift

public class DefaultDictionary {
    private let dict: LevelDbTable
    
    init(locale: String) {
        let dictsPath = DataFileManager.builtInEnglishDictDirectory
        
        if !DataFileManager.hasInstalled {
            fatalError("Data files not installed.")
        }
        
        dict = LevelDbTable(dictsPath + "/\(locale)", createDbIfMissing: false)
    }
    
    func getWords(wordLowercased: String) -> [String] {
        return dict.get(wordLowercased)?.split(separator: ",").map({ String($0) }) ?? []
    }
    
    public static func createDb(locale: String) {
        let dictionaryDirName = "\(Bundle.main.resourcePath!)/EnglishDictSource"
        let dictTextPath = "\(dictionaryDirName)/\(locale).txt"
        let commonDictPath = "\(dictionaryDirName)/common.txt"
        
        let dictDbPath = "\(DataFileManager.documentDirectory)/build/\(locale)"
        
        try? FileManager.default.removeItem(atPath: dictDbPath)
        try? FileManager.default.createDirectory(atPath: "\(DataFileManager.documentDirectory)/build", withIntermediateDirectories: false, attributes: nil)
        LevelDbTable.createEnglishDictionary([dictTextPath, commonDictPath], dictDbPath: dictDbPath)
        
        DDLogInfo("Dictionary genereated at \(dictDbPath)")
    }
}
