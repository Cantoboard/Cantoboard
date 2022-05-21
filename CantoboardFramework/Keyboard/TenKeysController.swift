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
    var specializationCaretPos = 0
    var specializationCaretPosOverride = -1 // This variable is set by "選拼音" button.
}

class TenKeysController {
    public static let filterBarDelimiter: Character = "\""
    
    weak var inputController: InputController?
    
    init(inputController: InputController) {
        self.inputController = inputController
    }
    
    func addSpecialization(candidateIndex: Int, holdCaret: Bool, state: inout TenKeysState) {
        guard let specialization = state.specializationCandidates[safe: candidateIndex]
            else { return }
        let specializationCaretPos = getSpecializationCaretPos(state)
        
        state.specializations[specializationCaretPos] = specialization
        state.selectedSpecializationCandidateIndex = candidateIndex
        state.specializationCaretPosOverride = holdCaret ? specializationCaretPos : -1
        update10KeysInput(state)
 
        DDLogInfo("TenKeysController addSpecialization \(specializationCaretPos) \(specialization)")
    }
    
    func removeLastSpecialization(_ state: inout TenKeysState) {
        if !state.specializations.isEmpty {
            let maxIndex = state.specializations.keys.max()!
            let removed = state.specializations.removeValue(forKey: maxIndex)
            DDLogInfo("TenKeysController Removing last specialization at \(maxIndex) \(removed ?? "")")
            resetTenKeysStateAfterRemovingSpecialization(&state)
            update10KeysInput(state)
        }
    }
    
    func removeSpecializations(after: Int, isAfterInclusive: Bool, _ state: inout TenKeysState) {
        for specialization in state.specializations {
            let specializationEndIndex = specialization.key + specialization.value.count + 1
            if specializationEndIndex > after || isAfterInclusive && specializationEndIndex == after {
                DDLogInfo("TenKeysController Removing specialization at \(specialization.key) \(specialization.value)")
                state.specializations.removeValue(forKey: specialization.key)
                resetTenKeysStateAfterRemovingSpecialization(&state)
            }
        }
        update10KeysInput(state)
    }
    
    private func resetTenKeysStateAfterRemovingSpecialization(_ state: inout TenKeysState) {
        state.selectedSpecializationCandidateIndex = nil
        state.specializationCaretPos = state.specializations.keys.max() ?? 0
        state.specializationCaretPosOverride = -1
    }
    
    private func update10KeysInput(_ state: TenKeysState) {
        guard let inputEngine = inputController?.inputEngine,
              let userComposition = inputEngine.englishComposition,
              let rimeRawInput = inputEngine.rimeRawInput
            else { return }
        let userInput = userComposition.text
        // Merge user input (stored in EnglishInputEngine) into Rime raw input.
        // Apply 10keys candidates specialization to the orignal raw user input.
        var specializedInput = ""
        var rimeIndex = 0
        var userIndex = 0
        var specializedCaretPos = -1
        outerLoop: while rimeIndex < rimeRawInput.text.count {
            if rimeIndex == rimeRawInput.caretIndex {
                specializedCaretPos = specializedInput.count
            }
            let rimeC = rimeRawInput.text.char(at: rimeIndex)!
            // DDLogInfo("TenKeysController DEBUG rawC \(rawC) i: \(i) letterSpaceIndex: \(letterSpaceIndex)")
            if rimeC.isEnglishLetterOrDigit,
               let tenKeysCandidate = state.specializations[rimeIndex] {
                // If specialization is defined starting at this rimeIndex, apply.
                specializedInput.append(tenKeysCandidate)
                specializedInput.append(Self.filterBarDelimiter)
                rimeIndex += tenKeysCandidate.count
                userIndex += tenKeysCandidate.count
                if rimeRawInput.caretIndex <= rimeIndex {
                    specializedCaretPos = specializedInput.count
                }
            } else {
                defer { rimeIndex += 1 }
                if rimeC == Self.filterBarDelimiter {
                    // Ignore all filter bar delimters as we regenerate them.
                    continue
                } else if rimeC == "'" {
                    // Keep user typed delimiter
                    specializedInput.append(rimeC)
                } else if let userC = userInput.char(at: userIndex) {
                    // To make sure we can undo specialization, copy original user input from EnglishInputEngine.
                    specializedInput.append(userC)
                    userIndex += 1
                }
            }
        }
        // specializedCaretPos could stay at -1 if no specialization has been specified and caret is at the end.
        if specializedCaretPos == -1 {
            specializedCaretPos = specializedInput.count
        }
        
        DDLogInfo("TenKeysController update10KeysInput rimeRawInput \(rimeRawInput.text) specializedRimeInput: \(specializedInput) caret: \(specializedCaretPos)")
        let specializedComposition = Composition(text: specializedInput, caretIndex: specializedCaretPos)
        inputEngine.setRimeInput(specializedComposition)
    }
    
    func clearInput(state: inout KeyboardState) {
        state.tenKeysState = TenKeysState()
    }
    
    func updateTenKeysCandidates(_ state: inout KeyboardState) {
        guard let inputEngine = inputController?.inputEngine,
              let rawInput = inputEngine.rimeRawInput?.text,
              let userInput = inputEngine.englishComposition?.text,
              !rawInput.isEmpty
        else {
            state.tenKeysState = TenKeysState()
            return
        }
        let specializationCaretPos = getSpecializationCaretPos(state.tenKeysState)
        // Raw input is specialized. To list possible romanization, we need the orignal user input.
        // Translate the caret pos from specialization string to user input string.
        let userCaretPos = Self.translateToLetterSpaceIndex(rawInput, index: specializationCaretPos)
        
        let pendingInputLen = userInput.count - userCaretPos
        let pendingInput = String(userInput.suffix(pendingInputLen))
        let newCandidate = Self.listNextCandidates(pendingInput)
        if state.tenKeysState.specializationCaretPos != specializationCaretPos ||
           state.tenKeysState.specializationCandidates != newCandidate {
            state.tenKeysState.specializationCandidates = newCandidate
            state.tenKeysState.selectedSpecializationCandidateIndex = nil
            state.tenKeysState.specializationCaretPos = specializationCaretPos
        }
    }
    
    private var candidateCommentCacheForCaretMovingMode: String?
    func caretMovingModeChanged(isInCaretMovingMode: Bool) {
        let rimeCandidateComment =  (inputController?.inputEngine.getRimeCandidateComment(0) ?? "").filter({ $0 != " " && !$0.isNumber })
        candidateCommentCacheForCaretMovingMode = isInCaretMovingMode ? rimeCandidateComment : nil
    }
    
    // LS stands for letter space.
    private func getSpecializationCaretPos(_ state: TenKeysState) -> Int {
        guard let inputEngine = inputController?.inputEngine,
              let userInput = inputEngine.englishComposition?.text,
              let rimeInput = inputEngine.rimeRawInput?.text,
              !userInput.isEmpty
            else { return 0 }
        
        var maxSpecializedIndex: Int
        if state.specializationCaretPosOverride != -1 &&
           state.specializations[state.specializationCaretPosOverride] != nil {
            maxSpecializedIndex = state.specializationCaretPosOverride
        } else {
            maxSpecializedIndex = state.specializations.reduce(0, {
                max($0, $1.key + $1.value.count + 1 /* for the delimiter */)
            })
        }
        
        while let c = rimeInput.char(at: maxSpecializedIndex), c == "'" || c == TenKeysController.filterBarDelimiter {
            maxSpecializedIndex += 1
        }
        // If we have specialized the whole strings, let the user to edit the last specialization.
        // Cap the caret pos to the beginning of the last specialization.
        // TODO replace this by another caret variable.
        if maxSpecializedIndex >= rimeInput.count {
            maxSpecializedIndex = state.specializations.keys.max()!
        }
        
        let rimeUserSelectedTextLength = inputEngine.rimeUserSelectedTextLength
        let specializationCaretPos = max(rimeUserSelectedTextLength, maxSpecializedIndex)
        return specializationCaretPos
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
        
        let rimeCompositionText = rimeComposition.text.filter({ $0 != " " })
        let rimeCompCaretSpaceCorrectedPos: Int
        if rimeComposition.caretIndex == 0 {
            // Rime has a special case that treats caretPos = 0 as caretPos = length
            rimeCompCaretSpaceCorrectedPos = rimeCompositionText.count
        } else {
            // Count number of spaces before the caret and deduce them from the caret pos.
            rimeCompCaretSpaceCorrectedPos = rimeComposition.caretIndex - rimeComposition.text.prefix(rimeComposition.caretIndex).filter({ $0 == " " }).count
        }
        
        // Remaining input excluding selected text.
        let inputRemaining = rimeRawInput.commonSuffix(with: rimeCompositionText)
        
        let rimeCandidateComment: String
        if let candidateCommentCache = candidateCommentCacheForCaretMovingMode {
            // Generate the new candidate comment by coping letters from candidateCommentCacheForCaretMovingMode
            // commas and spaces from current composition text
            var cacheIndex = candidateCommentCache.startIndex
            rimeCandidateComment = rimeCompositionText.reduce("", { r, c in
                guard c.isASCII else { return r }
                var r = r
                // DDLogInfo("TenKeysController generateBestComposition c '\(r)' '\(c)'")
                if c.isEnglishLetter && cacheIndex != candidateCommentCache.endIndex {
                    r.append(candidateCommentCache[cacheIndex])
                    cacheIndex = candidateCommentCache.index(after: cacheIndex)
                } else {
                    if c == "'" || c == "\"" {
                        if !r.isEmpty && r.last != " " {
                            r.append(" ")
                        }
                    } else {
                        // We ran out of char. That means the composition changed, some selected texts disappeared.
                        // In this case, we cannot use the cached comment. Return an empty string to show combo codes.
                        return ""
                    }
                }
                return r
            })
            // DDLogInfo("TenKeysController generateBestComposition rimeCandidateComment [\(rimeCandidateComment)] [\(candidateCommentCache)]")
        } else {
            rimeCandidateComment = inputEngine.getRimeCandidateComment(0) ?? ""
        }
        let candidateCode = rimeCandidateComment.filter { !$0.isNumber }
        
        var cIndex = candidateCode.startIndex
        var iIndex = inputRemaining.startIndex
        
        var morphedInput = ""
        // Scan the pending input string.
        while (iIndex < inputRemaining.endIndex) {
            let ic = inputRemaining[iIndex]
            
            // Ran out of candidate code. Just copy what's left in the input.
            if cIndex == candidateCode.endIndex {
                if ic == Self.filterBarDelimiter {
                    morphedInput.append("'")
                } else {
                    morphedInput.append(ic.lowercasedChar)
                }
                iIndex = inputRemaining.index(after: iIndex)
                continue
            }
            
            let cc = candidateCode[cIndex]
            
            // DDLogInfo("TenKeysController generateBestComposition iteration '\(ic)' '\(cc)'")
            if cc == " " {
                // If the candidate code is a space, append.
                if ic == "'" || ic == Self.filterBarDelimiter {
                    // Consume the "'" in input buffer
                    repeat {
                        morphedInput.append("'")
                        iIndex = inputRemaining.index(after: iIndex)
                    } while (iIndex != inputRemaining.endIndex && (inputRemaining[iIndex] == "'" || inputRemaining[iIndex] == Self.filterBarDelimiter))
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
                // Skip the space char too.
                if cIndex < candidateCode.endIndex {
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
        }
        
        let selectedInput = rimeCompositionText.prefix(rimeCompositionText.count - inputRemaining.count)
        DDLogInfo("TenKeysController generateBestComposition selectedInput '\(selectedInput)' morphedInput '\(morphedInput)'")
        
        let composition = String(selectedInput + morphedInput)
        let inputCaretPosFromTheRight = rimeCompositionText.count - rimeCompCaretSpaceCorrectedPos
        let caretPos: Int
        if inputCaretPosFromTheRight == 0 && rimeComposition.caretIndex == 0 {
            // Simulate special case in Rime that treats caretPos = length to caretPos = 0.
            caretPos = 0
        } else {
            caretPos = composition.count - inputCaretPosFromTheRight
        }
        
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
    
    private static func listNextCandidates(_ input: String) -> [String] {
        var input = input
        while input.first == "'" {
            input.removeFirst()
        }
        
        let prefixes = TenKeysHelper.listPossiblePrefixes(input) as! [String]
        var validPrefixes = Set<String>()
        
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
