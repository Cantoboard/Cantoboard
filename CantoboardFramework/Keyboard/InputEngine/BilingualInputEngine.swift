//
//  MixedModeInputEngine.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

class BilingualInputEngine: InputEngine {
    private static let processCharQueue = DispatchQueue(
        label: "org.cantoboard.process-char.queue",
        qos: .userInteractive,
        attributes: .concurrent)
    
    private let rimeInputEngine: RimeInputEngine
    private let englishInputEngine: EnglishInputEngine
    private weak var inputController: InputController?
    
    private(set) var composition: Composition?
    private(set) var candidatePaths:[CandidatePath] = []
    private(set) var isForcingRimeMode = false
    
    init(inputController: InputController, rimeSchema: RimeSchema) {
        self.inputController = inputController
        rimeInputEngine = RimeInputEngine(schema: rimeSchema)
        englishInputEngine = EnglishInputEngine()
    }

    var charForm: CharForm {
        get { rimeInputEngine.charForm }
        set {
            SessionState.main.lastCharForm = newValue
            rimeInputEngine.charForm = newValue
        }
    }

    var rimeSchema: RimeSchema {
        get { rimeInputEngine.schema }
        set { rimeInputEngine.schema = newValue }
    }
    
    var isComposing: Bool {
        !(rimeInputEngine.composition?.text.isEmpty ?? true)
    }
    
    func moveCaret(offset: Int) -> Bool {
        if isComposing {
            let updateRimeEngineState = rimeInputEngine.moveCaret(offset: offset)
            _ = updateEnglishCaretPosFromRime()
            updateComposition()
            
            // var englishInput = englishInputEngine.composition?.text ?? ""
            // var rimeInput = rimeInputEngine.rawInput?.text ?? ""
            // englishInput.insert("|", at: englishInput.index(englishInput.startIndex, offsetBy: englishInputEngine.composition?.caretIndex ?? 0) )
            // rimeInput.insert("|", at: rimeInput.index(rimeInput.startIndex, offsetBy: rimeInputEngine.rawInput?.caretIndex ?? 0))
            // DDLogInfo("BilingualInputEngine moveCaret \(rimeInput) \(englishInput)")
            return updateRimeEngineState
        } else {
            inputController?.textDocumentProxy?.adjustTextPosition(byCharacterOffset: offset)
            return false
        }
    }
    
    func processChar(_ char: Character) -> Bool {
        if char.isASCII {
            let queue = Self.processCharQueue
            let group = DispatchGroup()
            
            var updateEnglishEngineState = false, updateRimeEngineState = false
            queue.async(group: group) {
                updateRimeEngineState =
                self.rimeInputEngine.processChar(char)
            }
            englishInputEngine.textBeforeInput = inputController?.textDocumentProxy?.documentContextBeforeInput
            englishInputEngine.textAfterInput = inputController?.textDocumentProxy?.documentContextAfterInput
            englishInputEngine.disableTextOverride = !Settings.cached.isAutoCapEnabled || SessionState.main.lastInputMode == .chinese
            queue.async(group: group) {
                updateEnglishEngineState = self.englishInputEngine.processChar(char)
            }
            group.wait()
            updateComposition()
            return updateEnglishEngineState || updateRimeEngineState
        } else {
            return false
        }
    }
    
    func prepare() {
        self.rimeInputEngine.tryCreateRimeSessionIfNeeded()
    }
    
    func processRimeChar(_ char: Character) -> Bool {
        if char.isASCII {
            isForcingRimeMode = rimeInputEngine.processChar(char)
            updateComposition()
            return isForcingRimeMode
        } else {
            return false
        }
    }
    
    func processBackspace() -> Bool {
        if let rimeRawInput = rimeInputEngine.rawInput {
            guard rimeRawInput.caretIndex > 0 && rimeRawInput.caretIndex <= rimeRawInput.text.count else {
                DDLogInfo("processBackspace skipped. caretIndex is out of range. 0 < \(rimeRawInput.caretIndex) <= \(rimeRawInput.text.count)")
                return false
            }
            let rimeRawInputCaretPosBefore = rimeRawInput.caretIndex
            let charToBeDeleted = rimeRawInput.text[rimeRawInput.text.index(rimeRawInput.text.startIndex, offsetBy: rimeRawInput.caretIndex - 1)]
            let updateRime = rimeInputEngine.processBackspace()
            let rimeRawInputCaretPosAfter = self.rimeInputEngine.rawInput?.caretIndex ?? 0
            let rimeHasDeleted = rimeRawInputCaretPosBefore > rimeRawInputCaretPosAfter
            let updateEnglish = !charToBeDeleted.isRimeSpecialChar && rimeHasDeleted ? englishInputEngine.processBackspace() : false
            
            // DDLogInfo("Rime \(self.rimeInputEngine.rawInput?.text ?? "") \(self.rimeInputEngine.rawInput?.caretIndex ?? 0) ")
            // DDLogInfo("English \(englishComposition?.text ?? "") \(englishComposition?.caretIndex ?? 0)")
            // DDLogInfo("\(charToBeDeleted), \(charToBeDeleted.isRimeSpecialChar), \(rimeInputEngine.composition?.text), \(englishComposition?.text)")
                        
            isForcingRimeMode = self.rimeComposition?.text.contains(where: { $0.isRimeSpecialChar }) ?? false
            updateComposition()
            return updateEnglish || updateRime
        } else {
            inputController?.textDocumentProxy?.deleteBackward()
            return false
        }
    }
    
    func clearInput() {
        DDLogInfo("clearInput() called.")
        composition = nil
        rimeInputEngine.clearInput()
        englishInputEngine.clearInput()
        isForcingRimeMode = false
    }
    
    private func updateComposition() {
        if !isComposing {
            composition = nil
        } else if !isForcingRimeMode && englishInputEngine.isWord && rimeSchema.supportMixedMode && Settings.cached.isMixedModeEnabled {
            composition = englishComposition
        } else {
            guard let rimeComposition = rimeComposition else {
                composition = nil
                return
            }
            guard let englishComposition = englishComposition else {
                composition = rimeComposition
                return
            }
            
            let casedMorphedText = rimeComposition.text.caseMorph(caseForm: englishComposition.text)
            let casedMorphedComposition = Composition(text: casedMorphedText, caretIndex: rimeComposition.caretIndex)
            composition = casedMorphedComposition
        }
    }
    
    var englishComposition: Composition? {
        englishInputEngine.composition
    }
    
    var isEnglishWord: Bool {
        englishInputEngine.isWord
    }
    
    var englishCandidates: [String] {
        englishInputEngine.candidates
    }
    
    var englishPrefectCandidatesStartIndex: Int {
        englishInputEngine.prefectCandidatesStartIndex
    }
    
    var englishWorstCandidatesStartIndex: Int {
        englishInputEngine.worstCandidatesStartIndex
    }
    
    func selectEnglishCandidate(_ index: Int) -> String? {
        let commitedText = englishInputEngine.selectCandidate(index)
        if let commitedText = commitedText {
            EnglishInputEngine.userDictionary.learnWordIfNeeded(word: commitedText)
        } else {
            rimeInputEngine.clearInput()
        }
        updateComposition()
        return commitedText
    }
    
    func updateEnglishCandidates() {
        englishInputEngine.updateCandidates()
    }

    private func updateEnglishCaretPosFromRime() -> Bool {
        guard let rimeRawInput = rimeInputEngine.rawInput else { DDLogInfo("Bug check. rimeRawInput shouldn't be nil"); return true }
        // guard let englishComposition = englishComposition else { DDLogInfo("Bug check. englishComposition shouldn't be nil"); return true }
        let rimeRawInputBeforeCaret = rimeRawInput.text.prefix(rimeRawInput.caretIndex)
        let rimeRawInputCaretWithoutSpecialChars = rimeRawInputBeforeCaret.reduce(0, { r, c in
            let isRimeSpecialChar = c.isRimeSpecialChar || c == " "
            return r + (isRimeSpecialChar ? 0 : 1)
        })
        let updateEnglishEngineState = englishInputEngine.setCaret(position: rimeRawInputCaretWithoutSpecialChars)
        
        // DDLogInfo("Rime \(self.rimeInputEngine.rawInput?.text ?? "") \(self.rimeInputEngine.rawInput?.caretIndex ?? 0) ")
        // DDLogInfo("English \(englishComposition.text) \(rimeRawInputCaretWithoutSpecialChars)")
        
        return updateEnglishEngineState
    }
    
    var rimeRawInput: Composition? {
        rimeInputEngine.rawInput
    }
    
    var rimeComposition: Composition? {
        rimeInputEngine.composition
    }
    
    var isRimeFirstCandidateCompleteMatch: Bool {
        rimeInputEngine.isFirstCandidateCompleteMatch
    }
    
    func getRimeCandidate(_ index: Int) -> String? {
        return rimeInputEngine.getCandidate(index)
    }
    
    func getRimeCandidateComment(_ index: Int) -> String? {
        return rimeInputEngine.getCandidateComment(index)
    }
    
    var rimeLoadedCandidatesCount: Int {
        rimeInputEngine.loadedCandidatesCount
    }
    
    var hasRimeLoadedAllCandidates: Bool {
        rimeInputEngine.hasLoadedAllCandidates
    }
    
    var rimeUserSelectedTextLength: Int {
        rimeInputEngine.userSelectedTextLength
    }
    
    func loadMoreRimeCandidates() -> Bool {
        return rimeInputEngine.loadMoreCandidates()
    }
    
    func selectRimeCandidate(_ index: Int) -> String? {
        let commitedText = rimeInputEngine.selectCandidate(index)
        
        // User has selected a candidate and partially complete the composing text.
        if commitedText == nil {
            isForcingRimeMode = true
            _ = updateEnglishCaretPosFromRime()
        } else {
            englishInputEngine.clearInput()
        }
        updateComposition()
        return commitedText
    }
    
    func unlearnRimeCandidate(_ index: Int) -> Bool {
        return rimeInputEngine.unlearnCandidate(index)
    }
    
    func setRimeInput(_ composition: Composition) {
        rimeInputEngine.setInput(composition)
    }
}
 
