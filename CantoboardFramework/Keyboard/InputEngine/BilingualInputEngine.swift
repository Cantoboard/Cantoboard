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
        case english, rime
    }
    let source: Source
    let index: Int
}

class BilingualInputEngine: InputEngine {
    private static let processCharQueue = DispatchQueue(label: "org.cantoboard.process-char.queue", attributes: .concurrent)
    
    private let rimeInputEngine: RimeInputEngine
    private let englishInputEngine: EnglishInputEngine
    private let textDocumentProxy: UITextDocumentProxy
    
    private var candidates = NSMutableArray()
    private var candidatesSet = Set<String>()
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
        // User has selected a candidate and partially complete the composing text.
        if commitedText == nil {
            isForcingRimeMode = true
            _ = updateEnglishCaretPosFromRime()
        }
        updateInputState(true, true)
        return commitedText
    }
    
    func moveCaret(offset: Int) -> Bool {
        if isComposing {
            let updateRimeEngineState = rimeInputEngine.moveCaret(offset: offset)
            let updateEnglishEngineState = updateEnglishCaretPosFromRime()
            updateInputState(updateEnglishEngineState, updateRimeEngineState)
            return updateRimeEngineState
        } else {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
            return false
        }
    }
    
    private func updateEnglishCaretPosFromRime() -> Bool {
        guard let rimeRawInput = rimeInputEngine.rawInput else { NSLog("Bug check. rimeRawInput shouldn't be nil"); return true }
        // guard let englishComposition = englishComposition else { NSLog("Bug check. englishComposition shouldn't be nil"); return true }
        let rimeRawInputBeforeCaret = rimeRawInput.text.prefix(rimeRawInput.caretIndex)
        let rimeRawInputCaretWithoutSpecialChars = rimeRawInputBeforeCaret.reduce(0, { r, c in r + (c.isRimeSpecialChar || c == " " ? 0 : 1)})
        let updateEnglishEngineState = englishInputEngine.setCaret(position: rimeRawInputCaretWithoutSpecialChars)
        
        // NSLog("Rime \(self.rimeInputEngine.rawInput?.text ?? "") \(self.rimeInputEngine.rawInput?.caretIndex ?? 0) ")
        // NSLog("English \(englishComposition.text) \(rimeRawInputCaretWithoutSpecialChars)")
        
        return updateEnglishEngineState
    }
    
    func processChar(_ char: Character) -> Bool {
        if char.isASCII {
            let queue = BilingualInputEngine.processCharQueue
            let group = DispatchGroup()
            
            var updateEnglishEngineState = false, updateRimeEngineState = false
            queue.async(group: group) {
                updateRimeEngineState = self.rimeInputEngine.processChar(char.lowercasedChar)
            }
            queue.async(group: group) {
                updateEnglishEngineState = self.englishInputEngine.processChar(char)
            }
            group.wait()
            
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
        if let rimeRawInput = rimeInputEngine.rawInput {
            guard rimeRawInput.caretIndex > 0 && rimeRawInput.caretIndex <= rimeRawInput.text.count else {
                NSLog("processBackspace skipped. caretIndex is out of range. 0 < \(rimeRawInput.caretIndex) <= \(rimeRawInput.text.count)")
                return false
            }
            let rimeRawInputCaretPosBefore = rimeRawInput.caretIndex
            let charToBeDeleted = rimeRawInput.text[rimeRawInput.text.index(rimeRawInput.text.startIndex, offsetBy: rimeRawInput.caretIndex - 1)]
            let updateRime = rimeInputEngine.processBackspace()
            let rimeRawInputCaretPosAfter = self.rimeInputEngine.rawInput?.caretIndex ?? 0
            let rimeHasDeleted = rimeRawInputCaretPosBefore > rimeRawInputCaretPosAfter
            let updateEnglish = !charToBeDeleted.isRimeSpecialChar && rimeHasDeleted ? englishInputEngine.processBackspace() : false
            
            // NSLog("Rime \(self.rimeInputEngine.rawInput?.text ?? "") \(self.rimeInputEngine.rawInput?.caretIndex ?? 0) ")
            // NSLog("English \(englishComposition?.text ?? "") \(englishComposition?.caretIndex ?? 0)")
            // NSLog("\(charToBeDeleted), \(charToBeDeleted.isRimeSpecialChar), \(rimeInputEngine.composition?.text), \(englishComposition?.text)")
            
            updateInputState(updateEnglish, updateRime)
            
            isForcingRimeMode = self.rimeComposition?.text.contains(where: { $0.isRimeSpecialChar }) ?? false
            
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
                return englishComposition
            } else {
                guard let rimeComposition = rimeComposition else { return nil }
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
        englishInputEngine.composition
    }
    
    var rimeComposition: Composition? {
        rimeInputEngine.composition
    }
    
    private func resetCandidates() {
        curEnglishCandidateIndex = 0
        curRimeCandidateIndex = 0

        candidates = NSMutableArray()
        candidatePaths = NSMutableArray()
        candidatesSet = Set()
        
        hasLoadedAllBestRimeCandidates = false
    }
    
    private func updateInputState(_ updateEnglishInputState: Bool, _ updateRimeInputState: Bool) {
        guard updateEnglishInputState || updateRimeInputState else { return }
        
        // NSLog("English: \(englishInputEngine.composition?.text ?? "") Rime: \(rimeInputEngine.composition?.text ?? "")")
        resetCandidates()
        // populateCandidates()
    }
    
    private func populateCandidates() {
        guard let rimeComposingText = rimeComposition?.text else { return }
        let englishCandidates = Settings.cached.isMixedModeEnabled ? englishInputEngine.getCandidates() : []
        let rimeCandidates = rimeInputEngine.getCandidates()
        
        if englishInputEngine.isWord && curEnglishCandidateIndex < englishCandidates.count {
            addCurrentEnglishCandidate(englishCandidates)
        }
        
        // Populate the best Rime candidates. It's in the best candidates set if the user input is the prefix of candidate's composition.
        while !hasLoadedAllBestRimeCandidates && curRimeCandidateIndex < rimeCandidates.count {
            guard let candidate = rimeCandidates[curRimeCandidateIndex] as? String,
                  let comment = rimeInputEngine.getComment(curRimeCandidateIndex) else {
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            let composingTextWithOnlySyllables = rimeComposingText.filter { $0.isEnglishLetter }.lowercased()
            let commentWithOnlySyllables = comment.filter { $0.isEnglishLetter }.lowercased()
            // Rime doesn't return comment if the candidate's an exact match. If commentWithOnlySyllables's empty, treat it as a hit.
            if !commentWithOnlySyllables.isEmpty && !commentWithOnlySyllables.starts(with: composingTextWithOnlySyllables) &&
                candidate.count < composingTextWithOnlySyllables.count { // 聲母輸入 case
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            addCurrentRimeCandidate(rimeCandidates)
        }

        // Do not populate remaining English candidates until all best Rime candidates are populated.
        if !hasLoadedAllBestRimeCandidates && rimeInputEngine.loadMoreCandidates() { return }
        
        // Populate all English candidates with vowels.
        while !isForcingRimeMode && curEnglishCandidateIndex < englishCandidates.count {
            guard let englishCandidate = englishCandidates[curEnglishCandidateIndex] as? String,
                  englishCandidate.contains(where: { $0.isVowel || $0.isSymbol }) else { curEnglishCandidateIndex += 1; break }
            addCurrentEnglishCandidate(englishCandidates)
        }
        
        // Populate remaining Rime candidates.
        while curRimeCandidateIndex < rimeCandidates.count {
            addCurrentRimeCandidate(rimeCandidates)
        }
        
        // Populate remaining English candidates.
        while !isForcingRimeMode && curEnglishCandidateIndex < englishCandidates.count {
            addCurrentEnglishCandidate(englishCandidates)
        }
    }
    
    private func addCandidate(_ candidateText: String, source: CandidatePath.Source, index: Int) {
        if !candidatesSet.contains(candidateText) {
            candidatePaths.add(CandidatePath(source: source, index: index))
            candidates.add(candidateText)
            candidatesSet.insert(candidateText)
        }
    }
    
    private func addCurrentEnglishCandidate(_ englishCandidates: NSArray) {
        if let englishCandidate = englishCandidates[curEnglishCandidateIndex] as? String {
            addCandidate(englishCandidate, source: .english, index: curEnglishCandidateIndex)
        }
        curEnglishCandidateIndex += 1
    }
    
    private func addCurrentRimeCandidate(_ rimeCandidates: NSArray) {
        if let candidateText = rimeCandidates[curRimeCandidateIndex] as? String {
            addCandidate(candidateText, source: .rime, index: curRimeCandidateIndex)
        }
        curRimeCandidateIndex += 1
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
    
    func getCandidateSource(_ index: Int) -> CandidatePath.Source? {
        guard let path = candidatePaths[index] as? CandidatePath else { return nil }
        return path.source
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
