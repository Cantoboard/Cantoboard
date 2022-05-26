//
//  UserDictionary.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/8/21.
//

import Foundation

class UserDictionary {
    private static let userDictName = "UserDict"
    private let dict: LevelDbTable
    
    public init() {
        let userDataPath = DataFileManager.englishUserDictPath
        dict = LevelDbTable(userDataPath, createDbIfMissing: true)
    }
    
    func getWords(wordLowercased: String) -> [String] {
        guard let parsed = dict.get(wordLowercased)?.split(separator: ",").map({ String($0) }), parsed.count > 1 else { return [] }
        let freq = Int64(parsed[0]) ?? 0
        
        // To avoid over-learning, do not return words learnt less than 3 times.
        if freq < 3 { return [] };
        
        return parsed.suffix(parsed.count - 1)
    }
    
    func learnWord(word: String) {
        // Don't learn short words.
        guard word.count > 2 else { return }
        
        let key = word.lowercased()
        let row = dict.get(key)?.split(separator: ",")
        if let row = row {
            var freq = Int64(row[0]) ?? 0
            var wordSet = row.suffix(row.count - 1).mapToSet({ String($0) })
            wordSet.insert(word)
            freq += 1
            dict.put(key, value: "\(freq),\(wordSet.joined(separator: ","))")
        } else {
            dict.put(key, value: "1,\(word)")
            return
        }
    }
    
    func unlearn(word: String) -> Bool {
        let key = word.lowercased()
        let row = dict.get(key)?.split(separator: ",")
        if let row = row {
            var wordSet = row.suffix(row.count - 1).mapToSet({ String($0) })
            let freq = Int64(row[0]) ?? 0
            
            if wordSet.remove(word) != nil ||
               word.capitalized == word && wordSet.remove(word.lowercased()) != nil {
                if wordSet.isEmpty {
                    dict.delete(key)
                } else {
                    dict.put(key, value: "\(freq),\(wordSet.joined(separator: ","))")
                }
                return true
            }
        }
        return false
    }
    
    func learnWordIfNeeded(word: String) {
        if word.allSatisfy({ $0.isEnglishLetter }) &&
            !EnglishInputEngine.englishDictionary.getWords(wordLowercased: word.lowercased()).contains(word) {
            EnglishInputEngine.userDictionary.learnWord(word: word)
        }
    }
}
