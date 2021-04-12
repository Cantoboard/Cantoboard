//
//  EnglishInputEngine.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

import Foundation
import UIKit

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
    static var language = Settings.cached.englishLocale.rawValue {
        didSet {
            englishDictionary = DefaultDictionary(locale: language)
        }
    }
    private(set) static var englishDictionary = DefaultDictionary(locale: language)
    public static var userDictionary = UserDictionary()
    private var textDocumentProxy: UITextDocumentProxy!
    private var inputTextBuffer = InputTextBuffer()
    private var candidates = NSMutableArray()
    private static var textChecker = UITextChecker()
    private(set) var isWord: Bool = false
    private let highFreqWords = ["i'm", "can't", "let's"]
    
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
        DispatchQueue.global(qos: .background).async {
            _ = Self.englishDictionary
        }
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
        let text = inputTextBuffer.text, textLowercased = text.lowercased()
        guard !text.isEmpty && text.count < 25 else {
            isWord = false
            return
        }
        
        let documentContextBeforeInput = textDocumentProxy.documentContextBeforeInput
        let combined = (documentContextBeforeInput ?? "") + text
        let wordRange = combined.index(combined.endIndex, offsetBy: -text.count)..<combined.endIndex
        let nsWordRange = NSRange(wordRange, in: combined)
        var worstCandidates: [String] = []

        let textChecker = Self.textChecker
        let englishDictionary = Self.englishDictionary
        let userDictionary = Self.userDictionary
        
        let isInAppleDictionary = textChecker.rangeOfMisspelledWord(in: combined, range: nsWordRange, startingAt: 0, wrap: false, language: Self.language).location == NSNotFound
        let defaultEnglishDictionaryWords = englishDictionary.getWords(wordLowercased: textLowercased)
        let userDictionaryWords = userDictionary.getWords(wordLowercased: textLowercased)
        let englishDictionaryWords = defaultEnglishDictionaryWords + userDictionaryWords
        let englishDictionaryWordsSet = englishDictionaryWords.mapToSet({ String($0) })
        
        isWord = text != "m" && (!englishDictionaryWordsSet.isEmpty || text.allSatisfy({ $0.isUppercase }))
        
        candidates.removeAllObjects()
        isFirstLoad = true
        let spellCorrectionCandidates = textChecker.guesses(forWordRange: nsWordRange, in: combined, language: Self.language) ?? []
        
        // If the user is typing a word after an English word, run autocomplete.
        let autoCompleteCandidates: [String]
        if documentContextBeforeInput?.suffix(2).first?.isEnglishLetter ?? false {
            autoCompleteCandidates = textChecker.completions(forPartialWordRange: nsWordRange, in: combined, language: Self.language) ?? []
        } else {
            autoCompleteCandidates = []
        }
        
        englishDictionaryWordsSet.forEach({ word in
            var word = word
            if text.first!.isUppercase && word.first!.isLowercase && word.allSatisfy({ $0.isLowercase }) {
                word = word.capitalized
            }
            if word == text || word == "I" {
                candidates.insert(word, at: 0)
            } else {
                candidates.add(word)
            }
        })
        
        // TODO This's a hack to rule out words like Liu,Jiu which Apple considers as words.
        if isInAppleDictionary {
            candidates.add(text)
        }
        
        // If the dictionary doesn't contain the input word, but iOS considers it as a word, demote it.
        if isInAppleDictionary && !isWord {
            worstCandidates.append(text)
        }
        
        for word in spellCorrectionCandidates + autoCompleteCandidates {
            if word.isEmpty || word == text {
                continue // We added the word already. Ignore.
            } else if highFreqWords.contains(word.lowercased()) && word.filter({ $0.isEnglishLetter }).caseInsensitiveCompare(text) == .orderedSame {
                // Special case for correcting patterns like cant -> can't. lets -> let's.
                candidates.insert(word, at: 0)
                isWord = true
            } else if word.contains(where: { $0 == " " || $0 == "-" }) {
                worstCandidates.append(word)
            } else {
                let caseCorrectedCandidate = text.first!.isUppercase && word.first!.isLowercase ? word.capitalized : word
                if englishDictionaryWordsSet.contains(caseCorrectedCandidate) {
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
        return candidates[safe: index] as? String
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
