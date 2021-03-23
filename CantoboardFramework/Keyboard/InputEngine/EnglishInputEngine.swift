//
//  EnglishInputEngine.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

import Foundation
import UIKit

extension EnglishDictionary {
    public convenience init(locale: String) {
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dictDbPath = documentsDirectory.appendingPathComponent("EnglishDictionary/build/\(locale).db", isDirectory: false).path
        let dictDbImportedPath = dictDbPath + "/imported"
        // TODO compare the modified date of "EnglishDictionary/build/\(locale).db/LOCK". If the src is newer, reinstall.
        // try? FileManager.default.removeItem(atPath: dictDbPath)
        if !FileManager.default.fileExists(atPath: dictDbImportedPath) {
            guard let resourcePath = Bundle.init(for: EnglishDictionary.self).resourcePath else {
                fatalError("Bundle.main.resourcePath is nil.")
            }
            
            let srcDictPath = resourcePath + "/EnglishDictionary/build/\(locale).db"
            let dstDictPath = documentsDirectory.appendingPathComponent("EnglishDictionary/build", isDirectory: false).path
            try? FileManager.default.removeItem(atPath: dstDictPath)
            try! FileManager.default.createDirectory(atPath: dstDictPath, withIntermediateDirectories: true, attributes: nil)
            NSLog("Installing English Dictionary from \(srcDictPath) -> \(dstDictPath)")
            try! FileManager.default.copyItem(atPath: srcDictPath, toPath: dictDbPath)
            FileManager.default.createFile(atPath: dictDbImportedPath, contents: nil, attributes: nil)
        }
        
        self.init(dictDbPath)
    }
    
    public static func createDb(locale: String) {
        guard let resourcePath = Bundle.init(for: EnglishDictionary.self).resourcePath else {
            fatalError("Bundle.main.resourcePath is nil.")
        }
        let dictTextPath = resourcePath + "/EnglishDictionary/\(locale).txt"
        
        let documentsDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dictDbPath = documentsDirectory.appendingPathComponent("EnglishDictionary/build/\(locale).db", isDirectory: false).path
        
        try? FileManager.default.removeItem(atPath: dictDbPath)
        EnglishDictionary.createDb(dictTextPath, dbPath: dictDbPath)
    }
}

class InputTextBuffer {
    private(set) var _text: String
    private(set) var caretIndex: String.Index
    
    init() {
        _text = ""
        caretIndex = _text.endIndex
    }
    
    func insert(char: Character) {
        _text.insert(char, at: caretIndex)
        guard caretIndex != _text.endIndex else { return }
        caretIndex = _text.index(after: caretIndex)
        
        textOverride = nil
    }
        
    func moveCaret(offset: Int) -> Bool {
        guard abs(offset) == 1 else {
            NSLog("moveCaret offset \(offset) not supproted.")
            return false
        }
        
        let isMovingLeft = offset < 0
        if isMovingLeft {
            guard caretIndex != _text.startIndex else { return false }
            caretIndex = _text.index(before: caretIndex)
            return true
        } else {
            guard caretIndex != _text.endIndex else { return false }
            caretIndex = _text.index(after: caretIndex)
            return true
        }
    }
    
    func setCaret(position: Int) -> Bool {
        guard 0 <= position && position <= _text.count else {
            NSLog("setCaret position \(position) is OOB. Text length: \(_text.count)")
            return false
        }
        
        caretIndex = _text.index(_text.startIndex, offsetBy: position)
        return true
    }
    
    func clear() {
        _text = ""
        caretIndex = _text.endIndex
        textOverride = nil
    }
    
    func backspace() -> Bool {
        guard caretIndex != _text.startIndex else { return false }
        _text.remove(at: _text.index(before: caretIndex))
        _ = moveCaret(offset: -1)
        textOverride = nil
        return true
    }
    
    var caretPosition: Int {
        get {
            _text.distance(from: _text.startIndex, to: caretIndex)
        }
    }
    
    var textOverride: String?
    
    var text: String {
        textOverride == nil ? _text : textOverride!
    }
}

class EnglishInputEngine: InputEngine {
    private static let language = "en"
    private static let popularWords = ["I": "i", "I'm": "Im", "Can't": "Cant", "can't": "cant"]
    private var textDocumentProxy: UITextDocumentProxy!
    private var inputTextBuffer = InputTextBuffer()
    private var candidates = NSMutableArray()
    private static var textChecker = UITextChecker()
    private(set) var isWord: Bool = false
    private let englishDictionary = EnglishDictionary(locale: "en-US")
    
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
    }

    func processChar(_ char: Character) -> Bool {
        if char.isASCII {
            inputTextBuffer.insert(char: char)
            updateCandidates()
            return true
        }
        return false
    }
    
    func moveCaret(offset: Int) -> Bool {
        isFirstLoad = inputTextBuffer.moveCaret(offset: offset)
        return false
    }
    
    func setCaret(position: Int) -> Bool {
        isFirstLoad = inputTextBuffer.setCaret(position: position)
        return false
    }
    
    func clearInput() {
        inputTextBuffer.clear()
        updateCandidates()
    }
    
    func processBackspace() -> Bool {
        if inputTextBuffer.backspace() {
            updateCandidates()
            return true
        }
        return false
    }
    
    private func updateCandidates() {
        let text = inputTextBuffer.text
        guard !text.isEmpty && text.count < 25 else {
            isWord = false
            return
        }
        
        let documentContextBeforeInput = textDocumentProxy.documentContextBeforeInput
        let combined = (documentContextBeforeInput ?? "") + text
        let wordRange = combined.index(combined.endIndex, offsetBy: -text.count)..<combined.endIndex
        let nsWordRange = NSRange(wordRange, in: combined)
        var worstCandidates: [String] = []

        let textChecker = EnglishInputEngine.textChecker
        isWord = textChecker.rangeOfMisspelledWord(in: combined, range: nsWordRange, startingAt: 0, wrap: false, language: EnglishInputEngine.language).location == NSNotFound
        
        // If the dictionary doesn't contain the input word, but iOS considers it as a word, demote it.
        if isWord && !englishDictionary.hasWord(text) {
            worstCandidates.append(text)
            isWord = false
        }
        
        candidates.removeAllObjects()
        isFirstLoad = true
        
        let spellCorrectionCandidates = textChecker.guesses(forWordRange: nsWordRange, in: combined, language: EnglishInputEngine.language) ?? []
        
        // If the user is typing a word after an English word, run autocomplete.
        let autoCompleteCandidates: [String]
        if documentContextBeforeInput?.suffix(2).first?.isEnglishLetter ?? false {
            autoCompleteCandidates = textChecker.completions(forPartialWordRange: nsWordRange, in: combined, language: EnglishInputEngine.language) ?? []
        } else {
            autoCompleteCandidates = []
        }
        
        // Make sure the exact match appears first.
        if isWord && (text == "a" || text.count > 1) {
            candidates.insert(text, at: 0)
        }
        
        for word in spellCorrectionCandidates + autoCompleteCandidates {
            if word == text || // We added the word already. Ignore.
                /* word.contains("-") || */ word.contains(" ") { continue } // Only do word for word correction.
            if let popularWordInput = EnglishInputEngine.popularWords[word],
                text.caseInsensitiveCompare(popularWordInput) == .orderedSame {
                candidates.insert(word, at: 0)
            } else if word.caseInsensitiveCompare(text) == .orderedSame {
                candidates.insert(word, at: isWord ? 1 : 0)
                isWord = true
            } else {
                let caseCorrectedCandidate = text.first!.isUppercase ? word.capitalized : word
                // If the current candidate doesn't contain any vowels or symbol(short form), it isn't a good candidate.
                // if caseCorrectedCandidate.contains(where: { $0.isVowel || $0.isSymbol }) {
                if englishDictionary.hasWord(caseCorrectedCandidate) {
                    candidates.add(caseCorrectedCandidate)
                } else {
                    worstCandidates.append(caseCorrectedCandidate)
                }
            }
        }
        
        candidates.addObjects(from: worstCandidates)
        // NSLog("English candidates \(candidates)")
    }
    
    func getCandidates() -> NSArray {
        return candidates
    }
    
    func getCandidate(_ index: Int) -> String? {
        return candidates[index] as? String
    }
    
    private var isFirstLoad = false
    
    func loadMoreCandidates() -> Bool {
        let isFirstLoad = self.isFirstLoad
        self.isFirstLoad = false
        return isFirstLoad
    }
    
    func selectCandidate(_ index: Int) -> String? {
        return candidates[index] as? String
    }
    
    var composition: Composition? {
        get {
            return Composition(text: inputTextBuffer.text, caretIndex: inputTextBuffer.caretPosition)
        }
    }
}
