//
//  TenKeysController.swift
//  CantoboardFramework
//
//  Created by Alex Man on 4/30/22.
//

import Foundation
import CocoaLumberjackSwift

struct TenKeysState: Equatable {
    var specializationCandidates: [String] = []
    var selectedSpecializationCandidateIndex: Int?
    var specializations: [Int: String] = [:]
    var currentSpecializationCaretPos = 0
}

class TenKeysController {
    weak var inputController: InputController?
    
    init(inputController: InputController) {
        self.inputController = inputController
    }
    
    func addSpecialization(candidateIndex: Int, state: inout TenKeysState) {
        guard let specialization = state.specializationCandidates[safe: candidateIndex]
            else { return }
        let specializationCaretPosInLS = getSpecializationCaretPosInLS(state)
        
        state.specializations[specializationCaretPosInLS] = specialization
        state.selectedSpecializationCandidateIndex = candidateIndex
        update10KeysInput(state)
 
        DDLogInfo("TenKeysController addSpecialization \(specializationCaretPosInLS) \(specialization)")
    }
    
    func removeLastSpecialization(_ state: inout TenKeysState) {
        if !state.specializations.isEmpty {
            let maxIndex = state.specializations.keys.max()!
            let removed = state.specializations.removeValue(forKey: maxIndex)
            DDLogInfo("TenKeysController Removing last specialization at \(maxIndex) \(removed ?? "")")
            state.selectedSpecializationCandidateIndex = nil
            state.currentSpecializationCaretPos = state.specializations.keys.max() ?? 0
            update10KeysInput(state)
        }
    }
    
    func removeSpecializations(after: Int, isAfterInclusive: Bool, _ state: inout TenKeysState) {
        guard let inputEngine = inputController?.inputEngine,
              let userInput = inputEngine.englishComposition?.text
            else { return }
        
        let afterLS = Self.translateToLetterSpaceIndex(userInput, index: after)
        for specialization in state.specializations {
            let specializationEndIndex = specialization.key + specialization.value.count
            if specializationEndIndex > afterLS || isAfterInclusive && specializationEndIndex == afterLS {
                DDLogInfo("TenKeysController Removing specialization at \(specialization.key) \(specialization.value)")
                state.specializations.removeValue(forKey: specialization.key)
                state.selectedSpecializationCandidateIndex = nil
            }
        }
        update10KeysInput(state)
    }
    
    private func update10KeysInput(_ state: TenKeysState) {
        guard let inputEngine = inputController?.inputEngine,
              let userComposition = inputEngine.englishComposition
            else { return }
        
        let userInput = userComposition.text
        // Apply 10keys candidates specialization to the orignal raw user input.
        var specializedInput = ""
        var i = 0
        var letterSpaceIndex = 0
        outerLoop: while i < userInput.count {
            let rawC = userInput.char(at: i)!
            // DDLogInfo("TenKeysController DEBUG rawC \(rawC) i: \(i) letterSpaceIndex: \(letterSpaceIndex)")
            if rawC.isEnglishLetterOrDigit,
               let tenKeysCandidate = state.specializations[letterSpaceIndex] {
                specializedInput.append(tenKeysCandidate)
                specializedInput.append("'")
                i += tenKeysCandidate.count
                letterSpaceIndex += tenKeysCandidate.count
            } else {
                defer { i += 1 }
                if rawC == "'" && specializedInput.last == rawC { continue }
                specializedInput.append(rawC)
                if rawC.isEnglishLetterOrDigit { letterSpaceIndex += 1 }
            }
        }
        
        DDLogInfo("TenKeysController rawInput \(userInput) specializedRimeInput: \(specializedInput)")
        // let userCaretPosLS = Self.translateToLetterSpaceIndex(userInput, index: userComposition.caretIndex)
        // let specializedCaretPos = Self.translateFromLetterSpaceIndex(specializedInput, index: userCaretPosLS)
        // let specializedComposition = Composition(text: specializedInput, caretIndex: specializedInput.count)
        inputEngine.setRimeInput(specializedInput)
    }
    
    func clearInput(state: inout KeyboardState) {
        state.tenKeysState = TenKeysState()
    }
    
    func updateTenKeysCandidates(_ state: inout KeyboardState) {
        guard let inputEngine = inputController?.inputEngine,
              let userInput = inputEngine.englishComposition?.text,
              !userInput.isEmpty
            else {
            state.tenKeysState = TenKeysState()
            return
        }
        let specializationCaretPosInLS = getSpecializationCaretPosInLS(state.tenKeysState)
        let specializationCaretPos = Self.translateFromLetterSpaceIndex(userInput, index: specializationCaretPosInLS)
        let composingTextLen = userInput.count - specializationCaretPos
        // DDLogInfo("UFO updateTenKeysCandidates composingTextLen \(composingTextLen) \(userInput)")
        
        let newCandidate = Self.listNextCandidates(String(userInput.suffix(composingTextLen)))
        if state.tenKeysState.currentSpecializationCaretPos != specializationCaretPos ||
           state.tenKeysState.specializationCandidates != newCandidate {
            state.tenKeysState.specializationCandidates = newCandidate
            state.tenKeysState.selectedSpecializationCandidateIndex = nil
            state.tenKeysState.currentSpecializationCaretPos = specializationCaretPos
        }
    }
    
    // LS stands for letter space.
    private func getSpecializationCaretPosInLS(_ state: TenKeysState) -> Int {
        guard let inputEngine = inputController?.inputEngine,
              let userInput = inputEngine.englishComposition?.text,
              let rimeInput = inputEngine.rimeRawInput?.text,
              !userInput.isEmpty
            else { return 0 }
        
        var maxSpecializedIndexLS = state.specializations.reduce(0, {
            max($0, $1.key + $1.value.count)
        })
        // If we have specialized the whole strings, let the user to edit the last specialization.
        // Cap the caret pos to the beginning of the last specialization.
        if maxSpecializedIndexLS >= userInput.filter({ $0.isEnglishLetterOrDigit }).count {
            maxSpecializedIndexLS = state.specializations.keys.max()!
        }
        
        let rimeUserSelectedTextLength = inputEngine.rimeUserSelectedTextLength
        let rimeUserSelectedTextLengthLS = Self.translateToLetterSpaceIndex(rimeInput, index: rimeUserSelectedTextLength)
        // DDLogInfo("UFO DIU \(rimeInput) \(rimeUserSelectedTextLength) \(rimeUserSelectedTextLengthLS)")
        let specializationCaretPosInLS = max(rimeUserSelectedTextLengthLS, maxSpecializedIndexLS)
        // DDLogInfo("UFO getSpecializationCaretPosInLS specializationCaretPosInLS \(specializationCaretPosInLS) rimeUserSelectedTextLengthLS \(rimeUserSelectedTextLengthLS) maxSpecializedIndexLS \(maxSpecializedIndexLS)")
        return specializationCaretPosInLS
    }
    
    func shouldRemoveSpecializationOnBackspace(_ state: TenKeysState) -> Bool {
        guard let inputEngine = inputController?.inputEngine,
              let userInput = inputEngine.englishComposition?.text,
              let rimeInput = inputEngine.rimeRawInput?.text,
              !userInput.isEmpty
            else { return false }
        
        let maxSpecializedIndexLS = state.specializations.reduce(0, {
            max($0, $1.key + $1.value.count)
        })
        let rimeUserSelectedTextLength = inputEngine.rimeUserSelectedTextLength
        let rimeUserSelectedTextLengthLS = Self.translateToLetterSpaceIndex(rimeInput, index: rimeUserSelectedTextLength)
        
        return maxSpecializedIndexLS > rimeUserSelectedTextLengthLS
    }
    
    func generateBestComposition() -> Composition? {
        guard let inputEngine = inputController?.inputEngine,
              let rimeRawInput = inputEngine.rimeRawInput?.text,
              !rimeRawInput.isEmpty,
              let rimeComposition = inputEngine.rimeComposition else {
            return nil
        }
        let rimeCompositionText = inputEngine.rimeComposition?.text.filter({ $0 != " "}) ?? ""
        // DDLogInfo("UFO rimeRawInput \(rimeRawInput)")
        // DDLogInfo("UFO rimeCompositionText \(rimeCompositionText)")

        // Remaining input excluding selected text.
        let inputRemaining = rimeRawInput.commonSuffix(with: rimeCompositionText)
        // DDLogInfo("UFO inputRemaining '\(inputRemaining)'")

        let candidateCode = (inputEngine.getRimeCandidateComment(0) ?? "").filter { !$0.isNumber }
        // DDLogInfo("UFO candidateCode '\(candidateCode)'")

        var cIndex = candidateCode.startIndex
        var iIndex = inputRemaining.startIndex
        
        var morphedInput = ""
        // Scan the pending input string.
        while (iIndex < inputRemaining.endIndex) {
            let ic = inputRemaining[iIndex]
            
            // Ran out of candidate code. Just copy what's left in the input.
            if cIndex == candidateCode.endIndex {
                morphedInput.append(ic.lowercasedChar)
                iIndex = inputRemaining.index(after: iIndex)
                continue
            }
            
            let cc = candidateCode[cIndex]
            
            // DDLogInfo("UFO iteration '\(ic)' '\(cc)'")
            if cc == " " {
                // If the candidate code is a space, append.
                if ic == "'" {
                    // Consume the "'" in input buffer
                    repeat {
                        morphedInput.append("'")
                        iIndex = inputRemaining.index(after: iIndex)
                    } while (inputRemaining[iIndex] == "'")
                } else {
                    morphedInput.append(" ")
                }
                cIndex = candidateCode.index(after: cIndex)
            } else if ic == "'" {
                // Insert ' and skip to the code of the next candidate char
                morphedInput.append(ic)
                iIndex = inputRemaining.index(after: iIndex)
                
                while cIndex < candidateCode.endIndex && candidateCode[cIndex] != " " {
                    cIndex = candidateCode.index(after: cIndex)
                }
            } else {
                // Overwrite input char by the candidate code.
                if ic != cc && !Self.is10KeysSubKey(ic, cc) {
                    // If we encounter an input letter cannot be mapped to the current candidate letter,
                    // skip to next candidate char.
                    while cIndex < candidateCode.endIndex && candidateCode[cIndex] != " " {
                        cIndex = candidateCode.index(after: cIndex)
                    }
                    continue
                }
                morphedInput.append(cc)
                cIndex = candidateCode.index(after: cIndex)
                iIndex = inputRemaining.index(after: iIndex)
            }
            // DDLogInfo("UFO morphedInput '\(morphedInput)'")
        }
        
        let selectedInput = rimeCompositionText.prefix(rimeCompositionText.count - inputRemaining.count)
        // DDLogInfo("UFO selectedInput '\(selectedInput)'")
        
        let composition = String(selectedInput + morphedInput)
        // DDLogInfo("UFO composition '\(composition)'")
        let inputCaretPosFromTheRight = rimeComposition.text.count - rimeComposition.caretIndex
        let caretPos = composition.count - inputCaretPosFromTheRight
        return Composition(text: composition, caretIndex: caretPos)
    }
    
    private static func is10KeysSubKey(_ inputCode: Character, _ candidateCode: Character) -> Bool {
        switch candidateCode {
        case "a"..."c": return inputCode == "A"
        case "d"..."f": return inputCode == "D"
        case "g"..."i": return inputCode == "G"
        case "j"..."l": return inputCode == "J"
        case "m"..."o": return inputCode == "M"
        case "p"..."s": return inputCode == "P"
        case "t"..."v": return inputCode == "T"
        case "w"..."z": return inputCode == "W"
        default: return false
        }
    }
    
    public static func translateToLetterSpaceIndex(_ s: String, index: Int) -> Int {
        var letterCount = 0
        for i in 0..<index {
            if s.char(at: i)?.isEnglishLetterOrDigit ?? false {
                letterCount += 1
            }
        }
        return letterCount
    }
    
    public static func translateFromLetterSpaceIndex(_ s: String, index: Int) -> Int {
        var index = index
        var i = 0
        while index > 0 && i < s.count {
            if s.char(at: i)!.isEnglishLetterOrDigit {
                index -= 1
            }
            i += 1
        }
        return i
    }
    
    static func listNextCandidates(_ input: String) -> [String] {
        var input = input
        while input.first == "'" {
            input.removeFirst()
        }
        
        let prefixes = TenKeysHelper.listPossiblePrefixes(input) as! [String]
        var validPrefixes = Set<String>()
        // DDLogInfo("UFO input \(input)")
        
        for p in prefixes {
            var validPrefix = ""
            for (i, ic) in input.enumerated() {
                guard let cc = p.char(at: i) else { break }
                if ic == cc || Self.is10KeysSubKey(ic, cc) {
                    validPrefix.append(cc)
                } else {
                    break;
                }
            }
            if validPrefix.count == 1 || validPrefix.count == p.count {
                validPrefixes.insert(validPrefix)
            }
        }
        
        let sortedValidPrefixes = validPrefixes.sorted(by: {
            let lenDiff = $0.count - $1.count
            if lenDiff == 0 {
                return $0 < $1
            } else {
                return lenDiff > 0
            }
        })
        return sortedValidPrefixes
    }
}
