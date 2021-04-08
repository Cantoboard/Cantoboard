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
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let userDataPath = documentsDirectory.appendingPathComponent("RimeUserData/\(Self.userDictName)", isDirectory: true).path
        
        dict = LevelDbTable(userDataPath, createDbIfMissing: true)
    }
    
    func getWords(wordLowercased: String) -> [String.SubSequence] {
        guard let parsed = dict.get(wordLowercased)?.split(separator: ","), parsed.count > 1 else { return [] }
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
}
