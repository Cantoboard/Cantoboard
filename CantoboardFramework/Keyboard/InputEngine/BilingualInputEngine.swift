//
//  MixedModeInputEngine.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

import Foundation
import UIKit

struct CandidatePath {
    enum Source {
        case english
        case rime
    }
    let source: Source
    let index: Int
}

class BilingualInputEngine: InputEngine {
    private let rimeInputEngine: RimeInputEngine
    private let englishInputEngine: EnglishInputEngine
    private let textDocumentProxy: UITextDocumentProxy
    
    private var candidates = NSMutableArray()
    private var candidatePaths = NSMutableArray()
    private var curEnglishCandidateIndex = 0, curRimeCandidateIndex = 0
    private var hasLoadedAllBestRimeCandidates = false
    private var isForcingRimeMode = false
    
    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
        rimeInputEngine = RimeInputEngine()
        englishInputEngine = EnglishInputEngine(textDocumentProxy: textDocumentProxy)
    }
    
    private var isComposing: Bool {
        get {
            return composition?.text != nil
        }
    }
    
    func selectCandidate(_ index: Int) -> String? {
        guard let candidatePath = candidatePaths[index] as? CandidatePath else {
            NSLog("Invalid candidate %d selected. Count: %d", index, candidatePaths.count)
            return nil
        }
        
        var commitedText: String? = nil
        if candidatePath.source == .rime {
            commitedText = rimeInputEngine.selectCandidate(candidatePath.index)
        } else {
            commitedText = englishInputEngine.selectCandidate(candidatePath.index)
        }
        if commitedText != nil {
            clearInput()
        }
        updateInputState(true, true)
        return commitedText
    }
    
    func moveCaret(offset: Int) -> Bool {
        if isComposing {
            let updateRimeEngineState = rimeInputEngine.moveCaret(offset: offset)
            guard let rimeComposition = rimeInputEngine.composition else { NSLog("Bug check. rimeInputEngine.composition shouldn't be nil"); return true }
            let caretPosWithoutRimeSpecialChar = rimeComposition.text.prefix(rimeComposition.caretIndex).reduce(0, { r, c in r + (c.isRimeSpecialChar || c == " " ? 0 : 1)})
            let updateEnglishEngineState = englishInputEngine.setCaret(position: caretPosWithoutRimeSpecialChar)
            
            // NSLog("Rime \(rimeInputEngine.composition?.text) \(rimeInputEngine.composition?.caretIndex))")
            // NSLog("English \(englishInputEngine.composition?.text) \(englishInputEngine.composition?.caretIndex))")

            updateInputState(updateEnglishEngineState, updateRimeEngineState)
            return updateEnglishEngineState || updateRimeEngineState
        } else {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
            return false
        }
    }
    
    func processChar(_ char: Character) -> Bool {
        if char.isASCII {
            let updateEnglishEngineState = englishInputEngine.processChar(char)
            let updateRimeEngineState = rimeInputEngine.processChar(char.lowercasedChar)
            updateInputState(updateEnglishEngineState, updateRimeEngineState)
            return updateEnglishEngineState || updateRimeEngineState
        } else {
            return false
        }
    }
    
    func processRimeChar(_ char: Character) -> Bool {
        if char.isASCII {
            var updateRimeEngineState = rimeInputEngine.processChar(char)
            updateRimeEngineState = true
            isForcingRimeMode = true
            updateInputState(false, updateRimeEngineState)
            return updateRimeEngineState
        } else {
            return false
        }
    }
    
    func processBackspace() -> Bool {
        if let rimeComposition = rimeInputEngine.composition {
            let rimeCompositionText = rimeComposition.text
            guard rimeComposition.caretIndex > 0 && rimeComposition.caretIndex <= rimeCompositionText.count else {
                NSLog("processBackspace skipped. caretIndex is out of range. 0 < \(rimeComposition.caretIndex) <= \(rimeCompositionText.count)")
                return false
            }
            let charToBeDeleted = rimeCompositionText[rimeCompositionText.index(rimeCompositionText.startIndex, offsetBy: rimeComposition.caretIndex - 1)]
            let updateRime = rimeInputEngine.processBackspace()
            let updateEnglish = charToBeDeleted.isRimeSpecialChar ? false : englishInputEngine.processBackspace()
            
            // NSLog("\(charToBeDeleted), \(charToBeDeleted.isRimeSpecialChar), \(rimeInputEngine.composition?.text), \(englishComposition?.text)")
            
            updateInputState(updateEnglish, updateRime)
            
            isForcingRimeMode = rimeInputEngine.composition?.text.contains(where: { $0.isRimeSpecialChar }) ?? false
            
            return updateEnglish || updateRime
        } else {
            textDocumentProxy.deleteBackward()
            return false
        }
    }
    
    private func stripComposingTextAndClearInput(append: Character? = nil) -> String? {
        guard let text = composition?.text,
              !text.isEmpty  else {
            return nil
        }
        var textWithoutSpace = text.filter { $0 != " " }
        if let appendChar = append { textWithoutSpace.append(appendChar) }
        clearInput()
        updateInputState(true, true)
        return textWithoutSpace
    }
    
    var composition: Composition? {
        get {
            if !isForcingRimeMode && englishInputEngine.isWord {
                return englishInputEngine.composition
            } else {
                guard let rimeComposition = rimeInputEngine.composition else { return nil }
                guard let englishComposition = englishComposition else { return rimeComposition }
                
                let casedMorphedText = caseMorph(rimeText: rimeComposition.text, englishText: englishComposition.text)

                let casedMorphedComposition = Composition(text: casedMorphedText, caretIndex: rimeComposition.caretIndex)
                return casedMorphedComposition
            }
        }
    }
    
    // Apply the case if english text to rime text. e.g. rime text: a b'c, english text: Abc. Return A b'c
    private func caseMorph(rimeText: String, englishText: String) -> String {
        var casedMorphedText = ""
        
        var rimeTextCharIndex = rimeText.startIndex, englishTextCharIndex = englishText.startIndex
        while rimeTextCharIndex != rimeText.endIndex && englishTextCharIndex != englishText.endIndex {
            let rc = rimeText[rimeTextCharIndex], ec = englishText[englishTextCharIndex]
            if rc.isEnglishLetter {
                let isEnglishCharUppercased = ec.isUppercase
                if isEnglishCharUppercased {
                    casedMorphedText.append(rc.uppercased())
                } else {
                    casedMorphedText.append(rc.lowercased())
                }
            } else {
                casedMorphedText.append(rc)
            }
            rimeTextCharIndex = rimeText.index(after: rimeTextCharIndex)
            if rc != " " && rc != "'" {
                englishTextCharIndex = englishText.index(after: englishTextCharIndex)
            }
        }
        while rimeTextCharIndex != rimeText.endIndex {
            casedMorphedText.append(rimeText[rimeTextCharIndex])
            rimeTextCharIndex = rimeText.index(after: rimeTextCharIndex)
        }
        return casedMorphedText
    }
    
    var englishComposition: Composition? {
        get { englishInputEngine.composition }
    }
    
    private func resetCandidates() {
        curEnglishCandidateIndex = 0
        curRimeCandidateIndex = 0

        candidates = NSMutableArray()
        candidatePaths = NSMutableArray()
        
        hasLoadedAllBestRimeCandidates = false
    }
    
    private func updateInputState(_ updateEnglishInputState: Bool, _ updateRimeInputState: Bool) {
        guard updateEnglishInputState || updateRimeInputState else { return }
        
        // NSLog("English: \(englishInputEngine.composition?.text ?? "") Rime: \(rimeInputEngine.composition?.text ?? "")")
        // print("updateInputState resetCandidates")
        resetCandidates()
        // populateCandidates()
    }
    
    private func populateCandidates() {
        guard let rimeComposingText = rimeInputEngine.composition?.text,
              let englishComposingText = englishInputEngine.composition?.text
            else { return }
        let englishCandidates = Settings.cached.isEnglishEnabled ? englishInputEngine.getCandidates() : []
        let rimeCandidates = rimeInputEngine.getCandidates()
        
        // Populate the best Rime candidates. It's in the best candidates set if the user input is the prefix of candidate's composition.
        while !hasLoadedAllBestRimeCandidates && curRimeCandidateIndex < rimeCandidates.count {
            guard let comment = rimeInputEngine.getComment(curRimeCandidateIndex) else {
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            let composingTextWithOnlySyllables = rimeComposingText.filter { $0.isEnglishLetter }.lowercased()
            let commentWithOnlySyllables = comment.filter { $0.isEnglishLetter }.lowercased()
            // Rime doesn't return comment if the candidate's an exact match. If commentWithOnlySyllables's empty, treat it as a hit.
            if !commentWithOnlySyllables.isEmpty && !commentWithOnlySyllables.starts(with: composingTextWithOnlySyllables) {
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            candidatePaths.add(CandidatePath(source: .rime, index: curRimeCandidateIndex))
            candidates.add(rimeCandidates[curRimeCandidateIndex])
            
            curRimeCandidateIndex += 1
        }
        
        // Do not populate English candidates until all best Rime candidates are populated/
        if !hasLoadedAllBestRimeCandidates && rimeInputEngine.loadMoreCandidates() { return }
        
        // Populate all English candidates.
        while !isForcingRimeMode && curEnglishCandidateIndex < englishCandidates.count {
            let englishCandidate = englishCandidates[curEnglishCandidateIndex] as! String
            if englishCandidate.caseInsensitiveCompare(englishComposingText) == .orderedSame {
                candidatePaths.insert(CandidatePath(source: .english, index: curEnglishCandidateIndex), at: 0)
                candidates.insert(englishCandidate, at: 0)
            } else {
                candidatePaths.add(CandidatePath(source: .english, index: curEnglishCandidateIndex))
                candidates.add(englishCandidate)
            }
            curEnglishCandidateIndex += 1
        }
        
        // Populate the rest of the Rime candidates.
        while curRimeCandidateIndex < rimeCandidates.count {
            if let candidate = rimeCandidates[curRimeCandidateIndex] as? String,
               !candidate.starts(with: "__") {
                candidatePaths.add(CandidatePath(source: .rime, index: curRimeCandidateIndex))
                candidates.add(rimeCandidates[curRimeCandidateIndex])
            }
            curRimeCandidateIndex += 1
        }
    }
    
    func clearInput() {
        NSLog("clearInput() called.")
        rimeInputEngine.clearInput()
        englishInputEngine.clearInput()
        // print("clearInput resetCandidates. rimeInputEngine composition", rimeInputEngine.composition?.text, englishInputEngine.composition?.text)
        resetCandidates()
        isForcingRimeMode = false
        // setComposingText(nil)
    }
    
    func getCandidates() -> NSArray {
        return candidates
    }
    
    func getCandidate(_ index: Int) -> String? {
        return candidates[index] as? String
    }
    
    func loadMoreCandidates() -> Bool {
        let hasLoadedNew = rimeInputEngine.loadMoreCandidates() || englishInputEngine.loadMoreCandidates()
        if hasLoadedNew { populateCandidates() }
        return hasLoadedNew
    }
    
    func refreshChineseScript() {
        rimeInputEngine.refreshChineseScript()
        resetCandidates()
    }
}
