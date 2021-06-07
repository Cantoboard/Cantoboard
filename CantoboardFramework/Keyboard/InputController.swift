//
//  InputHandler.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/26/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift
import ZIPFoundation

enum ContextualType: Equatable {
    case english, chinese, rime, url(isRimeComposing: Bool)
}

struct KeyboardState: Equatable {
    var keyboardType: KeyboardType {
        didSet {
            symbolShapeOverride = nil
        }
    }
    var keyboardContextualType: ContextualType
    var symbolShapeOverride: SymbolShape?
    
    // var isEnabled: Bool
    // var isLoading: Bool
    
    var returnKeyType: UIReturnKeyType
    var needsInputModeSwitchKey: Bool
    
    var mainSchema: RimeSchema, reverseLookupSchema: RimeSchema?
    var inputMode: InputMode = Settings.cached.lastSessionSettings.lastInputMode
    
    var activeSchema: RimeSchema {
        get { reverseLookupSchema ?? mainSchema }
    }
    
    var symbolShape: SymbolShape {
        symbolShapeOverride ?? (keyboardContextualType == .chinese ? .full : .half)
    }
    
    init() {
        keyboardType = KeyboardType.alphabetic(.lowercased)
        keyboardContextualType = .english
        
        // isEnabled = true
        // isLoading = false
        
        returnKeyType = .default
        needsInputModeSwitchKey = false
        
        mainSchema = Settings.cached.lastSessionSettings.lastPrimarySchema
        inputMode = Settings.cached.lastSessionSettings.lastInputMode
    }
}

class InputController {
    private static let feedbackGenerator = UIImpactFeedbackGenerator()
    
    private weak var keyboardViewController: KeyboardViewController?
    private(set) var inputEngine: BilingualInputEngine!
    
    private(set) var state: KeyboardState = KeyboardState()
    
    private var lastKey: KeyboardAction?
    private var isHoldingShift = false
        
    private var hasInsertedAutoSpace = false
    private var shouldApplyChromeSearchBarHack = false, shouldSkipNextTextDidChange = false
    private var needClearInput = false
    
    private var prevTextBefore: String?
    
    private(set) var candidateOrganizer: CandidateOrganizer!
    
    var textDocumentProxy: UITextDocumentProxy? {
        keyboardViewController?.textDocumentProxy
    }
    
    private var keyboardView: KeyboardView? {
        keyboardViewController?.keyboardView
    }
    
    init(keyboardViewController: KeyboardViewController) {
        self.keyboardViewController = keyboardViewController
        inputEngine = BilingualInputEngine(inputController: self, rimeSchema: state.mainSchema)
        candidateOrganizer = CandidateOrganizer(inputController: self)
        
        enforceInputMode()
    }
    
    func textWillChange(_ textInput: UITextInput?) {
        prevTextBefore = textDocumentProxy?.documentContextBeforeInput
        // DDLogInfo("textWillChange \(prevTextBefore)")
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        if let keyboardViewController = keyboardViewController,
           let keyboardAppearance = keyboardViewController.textDocumentProxy.keyboardAppearance {
            switch keyboardAppearance {
            case .dark: keyboardViewController.overrideUserInterfaceStyle = .dark
            case .light: keyboardViewController.overrideUserInterfaceStyle = .light
            default: keyboardViewController.overrideUserInterfaceStyle = .unspecified
            }
        }
        
        // DDLogInfo("textDidChange prevTextBefore \(prevTextBefore) documentContextBeforeInput \(textDocumentProxy?.documentContextBeforeInput)")
        shouldApplyChromeSearchBarHack = isTextChromeSearchBar()
        if prevTextBefore != textDocumentProxy?.documentContextBeforeInput && !shouldSkipNextTextDidChange {
            clearInput(shouldLeaveReverseLookupMode: false)
        } else if inputEngine.composition != nil, !shouldApplyChromeSearchBarHack {
            self.updateMarkedText()
        }
        
        shouldSkipNextTextDidChange = false
        updateInputState()
    }
    
    private func updateContextualSuggestion() {
        checkAutoCap()
        refreshKeyboardContextualType()
        showAutoSuggestCandidates()
    }
    
    private func candidateSelected(choice: IndexPath, enableSmartSpace: Bool) {
        if let commitedText = candidateOrganizer.selectCandidate(indexPath: choice) {
            if commitedText.allSatisfy({ $0.isEnglishLetter }) {
                EnglishInputEngine.userDictionary.learnWord(word: commitedText)
            }
            insertText(commitedText, isFromCandidateBar: enableSmartSpace)
            if !candidateOrganizer.shouldCloseCandidatePaneOnCommit {
                keyboardView?.candidatePaneView?.changeMode(.row)
            }
        }
    }
    
    private func candidateLongPressed(choice: IndexPath) {
        if let text = candidateOrganizer.getCandidate(indexPath: choice), text.allSatisfy({ $0.isEnglishLetter }) {
            if EnglishInputEngine.userDictionary.unlearnWord(word: text) {
                Self.feedbackGenerator.impactOccurred()
            }
        }
    }
    
    private func handleSpace() {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        if inputEngine.isComposing && candidateOrganizer.getCandidateCount(section: 0) > 0 {
            candidateSelected(choice: [0, 0], enableSmartSpace: true)
        } else {
            if !insertComposingText() {
                if !handleAutoSpace() {
                    textDocumentProxy.insertText(" ")
                }
            }
        }
    }
    
    private var cachedActions: [KeyboardAction] = []
    
    func reenableKeyboard() {
        DispatchQueue.main.async {
            guard RimeApi.shared.state == .succeeded else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: self.reenableKeyboard)
                return
            }
            DDLogInfo("Enabling keyboard.")
            self.cachedActions.forEach({ self.keyPressed($0) })
            self.cachedActions = []
            self.keyboardView?.setEnable(isEnabled: true, isLoading: false)
        }
    }
    
    func keyPressed(_ action: KeyboardAction) {
        guard RimeApi.shared.state == .succeeded else {
            // If RimeEngine isn't ready, disable the keyboard.
            DDLogInfo("Disabling keyboard")
            self.keyboardView?.setEnable(isEnabled: false, isLoading: true)
            cachedActions.append(action)
            return
        }
        
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        defer {
            lastKey = action
            keyboardView?.state = state
        }
        
        needClearInput = false
        let isComposing = inputEngine.isComposing
        
        switch action {
        case .moveCursorForward, .moveCursorBackward:
            moveCursor(offset: action == .moveCursorBackward ? -1 : 1)
        case .character(let c):
            guard let char = c.first else { return }
            if !isComposing && shouldApplyChromeSearchBarHack {
                self.shouldSkipNextTextDidChange = true
                textDocumentProxy.insertText("")
            }
            let shouldFeedCharToInputEngine = char.isASCII && char.isLetter && c.count == 1
            if !(shouldFeedCharToInputEngine && inputEngine.processChar(char)) {
                if !insertComposingText(appendBy: c) {
                    insertText(c)
                }
            }
            if !isHoldingShift && state.keyboardType == .some(.alphabetic(.uppercased)) {
                state.keyboardType = .alphabetic(.lowercased)
            }
        case .rime(let rc):
            guard isComposing || rc == .sym else { return }
            _ = inputEngine.processRimeChar(rc.rawValue)
        case .space:
            handleSpace()
        case .newLine:
            if !insertComposingText(shouldDisableSmartSpace: true) {
                insertText("\n")
            }
        case .backspace, .deleteWord, .deleteWordSwipe:
            if state.reverseLookupSchema != nil && !isComposing {
                state.reverseLookupSchema = nil
            } else if isComposing {
                if action == .deleteWordSwipe {
                    needClearInput = true
                } else {
                    _ = inputEngine.processBackspace()
                }
                if !inputEngine.isComposing {
                    keyboardView?.candidatePaneView?.changeMode(.row)
                }
            } else {
                switch action {
                case .backspace: textDocumentProxy.deleteBackward()
                case .deleteWord: textDocumentProxy.deleteBackwardWord()
                case .deleteWordSwipe:
                    if textDocumentProxy.documentContextBeforeInput?.last?.isASCII ?? false {
                        textDocumentProxy.deleteBackwardWord()
                    } else {
                        textDocumentProxy.deleteBackward()
                    }
                default:()
                }
            }
        case .emoji(let e):
            AudioFeedbackProvider.play(keyboardAction: action)
            if !insertComposingText(appendBy: e, shouldDisableSmartSpace: true) {
                textDocumentProxy.insertText(e)
            }
        case .shiftDown:
            isHoldingShift = true
            state.keyboardType = .alphabetic(.uppercased)
            return
        case .shiftUp:
            state.keyboardType = .alphabetic(.lowercased)
            isHoldingShift = false
            return
        case .shiftRelax:
            isHoldingShift = false
            return
        case .keyboardType(let type):
            state.keyboardType = type
            self.checkAutoCap()
            return
        case .setCharForm(let cs):
            inputEngine.charForm = cs
            candidateOrganizer.updateCandidates(reload: true)
            
            var settings = Settings.cached
            settings.charForm = cs
            Settings.save(settings)
            return
        case .toggleInputMode:
            guard state.reverseLookupSchema == nil else {
                // Disable reverse look up mode on tap.
                state.reverseLookupSchema = nil
                changeSchema()
                return
            }
            
            switch state.inputMode {
            case .mixed: state.inputMode = .english
            case .chinese: state.inputMode = .english
            case .english: state.inputMode = Settings.cached.isMixedModeEnabled ? .mixed : .chinese
            }
            enforceInputMode()
            
            var settings = Settings.cached
            settings.lastSessionSettings.lastInputMode = state.inputMode
            Settings.save(settings)
        case .toggleSymbolShape:
            switch state.symbolShape {
            case .full: state.symbolShapeOverride = .half
            case .half: state.symbolShapeOverride = .full
            default: ()
            }
        case .reverseLookup(let schema):
            state.reverseLookupSchema = schema
            changeSchema()
            return
        case .changeSchema(let schema):
            state.mainSchema = schema
            var settings = Settings.cached
            settings.lastSessionSettings.lastPrimarySchema = schema
            Settings.save(settings)
            changeSchema()
            return
        case .selectCandidate(let choice):
            candidateSelected(choice: choice, enableSmartSpace: true)
        case .longPressCandidate(let choice):
            candidateLongPressed(choice: choice)
        case .exportFile(let namePrefix, let path):
            keyboardView?.setEnable(isEnabled: false, isLoading: true)
            
            let zipFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("\(namePrefix)-\(NSDate().timeIntervalSince1970).zip")
            DispatchQueue.global(qos: .userInteractive).async { [self] in
                do {
                    try FileManager.default.zipItem(at: URL(fileURLWithPath: path, isDirectory: true), to: zipFilePath)
                    let share = UIActivityViewController(activityItems: [zipFilePath], applicationActivities: nil)
                    DispatchQueue.main.async { keyboardViewController?.present(share, animated: true, completion: nil) }
                } catch {
                    DDLogError("Failed to export \(namePrefix) at \(path).")
                }
                DispatchQueue.main.async {
                    self.keyboardView?.setEnable(isEnabled: true, isLoading: false)
                }
            }
        case .exit: exit(0)
        default: ()
        }
        if needClearInput {
            clearInput()
        } else {
            updateInputState()
        }
    }
    
    func enforceInputMode() {
        if Settings.cached.isMixedModeEnabled && state.inputMode == .chinese { state.inputMode = .mixed }
        if !Settings.cached.isMixedModeEnabled && state.inputMode == .mixed { state.inputMode = .chinese }
    }
    
    private func isTextChromeSearchBar() -> Bool {
        guard let textFieldType = textDocumentProxy?.keyboardType else { return false }
        //print("isTextChromeSearchBar", textFieldType, textDocumentProxy.documentContextBeforeInput)
        return textFieldType == UIKeyboardType.webSearch
    }
    
    private func shouldApplyAutoCap() -> Bool {
        guard let textDocumentProxy = textDocumentProxy else { return false }
        //print("autocapitalizationType", textDocumentProxy.autocapitalizationType?.rawValue)
        if textDocumentProxy.autocapitalizationType == .some(.none) { return false }
        if inputEngine.composition?.text != nil { return false }
        
        // There are three cases we should apply auto cap:
        // - First char in the doc. nil
        // - Half shaped: e.g. ". " -> "<sym><space>"
        // - Full shaped: e.g. "。" -> "<sym>"
        let lastChar = textDocumentProxy.documentContextBeforeInput?.last
        let lastSymbol = textDocumentProxy.documentContextBeforeInput?.last(where: { $0 != " " })
        // DDLogInfo("documentContextBeforeInput \(textDocumentProxy.documentContextBeforeInput) \(lastChar)")
        let isFirstCharInDoc = lastChar == nil || lastChar == "\n"
        let isHalfShapedCase = (lastChar?.isWhitespace ?? false && lastSymbol?.isHalfShapeTerminalPunctuation ?? false)
        let isFullShapedCase = lastChar?.isFullShapeTerminalPunctuation ?? false
        return isFirstCharInDoc || isHalfShapedCase || isFullShapedCase
    }
    
    private func checkAutoCap() {
        guard Settings.cached.isAutoCapEnabled && !isHoldingShift && state.reverseLookupSchema == nil &&
                (state.keyboardType == .alphabetic(.lowercased) || state.keyboardType == .alphabetic(.uppercased))
            else { return }
        state.keyboardType = shouldApplyAutoCap() ? .alphabetic(.uppercased) : .alphabetic(.lowercased)
    }
    
    private func changeSchema() {
        inputEngine.rimeSchema = state.activeSchema
    }
    
    private func clearInput(shouldLeaveReverseLookupMode: Bool = true) {
        inputEngine.clearInput()
        updateInputState()
        if shouldLeaveReverseLookupMode {
            state.reverseLookupSchema = nil
            changeSchema()
        }
    }
    
    func clearState() {
        // clearInput()
        hasInsertedAutoSpace = false
        shouldSkipNextTextDidChange = false
        lastKey = nil
        prevTextBefore = nil
    }
    
    private var hasMarkedText = false
    
    private func insertText(_ text: String, isFromCandidateBar: Bool = false) {
        guard !text.isEmpty else { return }
        guard let textDocumentProxy = textDocumentProxy else { return }
        let isNewLine = text == "\n"
        
        if shouldRemoveSmartSpace(text) {
            // If there's marked text, we've to make an extra call to deleteBackward to remove the marked text before we could delete the space.
            if hasMarkedText {
                textDocumentProxy.deleteBackward()
                // If we hit this case, textDocumentProxy.documentContextBeforeInput will no longer be in-sync with the text of the document,
                // It will contain part of the marked text which the doc doesn't contain.
                // Fortunately, contextual update looks at the tail of the documentContextBeforeInput only.
                // After inserting text, the inaccurate text doesn't affect the contextual update.
            }
            textDocumentProxy.deleteBackward()
            hasInsertedAutoSpace = false
        }
        
        let textToBeInserted: String
        
        if shouldInsertSmartSpace(text, isFromCandidateBar, isNewLine) {
            textToBeInserted = text + " "
            hasInsertedAutoSpace = true
        } else {
            textToBeInserted = text
            hasInsertedAutoSpace = false
        }
        
        if hasMarkedText {
            textDocumentProxy.setMarkedText(textToBeInserted, selectedRange: NSRange(location: textToBeInserted.count, length: 0))
            textDocumentProxy.unmarkText()
            hasMarkedText = false
        } else {
            textDocumentProxy.insertText(textToBeInserted)
        }
        
        needClearInput = true
        
        // DDLogInfo("insertText() hasInsertedAutoSpace \(hasInsertedAutoSpace) isLastInsertedTextFromCandidate \(isLastInsertedTextFromCandidate)")
    }
    
    private func updateInputState() {
        updateMarkedText()
        updateContextualSuggestion()
        candidateOrganizer.updateCandidates(reload: true)
        
        state.returnKeyType = hasMarkedText ? .default : textDocumentProxy?.returnKeyType ?? .default
        state.needsInputModeSwitchKey = keyboardViewController?.needsInputModeSwitchKey ?? false
        keyboardView?.state = state
    }
    
    private func updateMarkedText() {
        switch state.inputMode {
        case .chinese: setMarkedText(inputEngine.rimeComposition)
        case .english: setMarkedText(inputEngine.englishComposition)
        case .mixed: setMarkedText(inputEngine.composition)
        }
    }
    
    private func setMarkedText(_ composition: Composition?) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        guard var text = composition?.text, !text.isEmpty else {
            if hasMarkedText {
                textDocumentProxy.setMarkedText("", selectedRange: NSRange(location: 0, length: 0))
                textDocumentProxy.unmarkText()
                hasMarkedText = false
            }
            return
        }
        var caretPosition = composition?.caretIndex ?? NSNotFound
        
        let inputType = textDocumentProxy.keyboardType ?? .default
        let shouldStripSpace = inputType == .URL || inputType == .emailAddress || inputType == .webSearch
        if shouldStripSpace {
            let spaceStrippedSpace = text.filter { $0 != " " }
            caretPosition -= text.prefix(caretPosition).reduce(0, { $0 + ($1 != " " ? 0 : 1) })
            text = spaceStrippedSpace
        }
        
        textDocumentProxy.setMarkedText(text, selectedRange: NSRange(location: caretPosition, length: 0))
        hasMarkedText = true
    }
    
    private var shouldEnableSmartInput: Bool {
        guard let textFieldType = textDocumentProxy?.keyboardType else { return true }
        return textFieldType != .URL &&
            textFieldType != .asciiCapableNumberPad &&
            textFieldType != .decimalPad &&
            textFieldType != .emailAddress &&
            textFieldType != .namePhonePad &&
            textFieldType != .numberPad &&
            textFieldType != .numbersAndPunctuation &&
            textFieldType != .phonePad;
    }
    
    private func insertComposingText(appendBy: String? = nil, shouldDisableSmartSpace: Bool = false) -> Bool {
        if let englishText = inputEngine.englishComposition?.text,
           var composingText = inputEngine.composition?.text.filter({ $0 != " " }),
           !composingText.isEmpty {
            if Settings.cached.toneInputMode == .vxq {
                var englishTailLength = 0
                for c in composingText.reversed() {
                    switch c {
                    case "4", "5", "6": englishTailLength += 2
                    case c where !c.isASCII: break
                    default: englishTailLength += 1
                    }
                }
                let composingTextWithTonesReplaced = String(composingText.prefix(while: { !$0.isASCII }) + englishText.suffix(englishTailLength))
                composingText = composingTextWithTonesReplaced
            }
            EnglishInputEngine.userDictionary.learnWordIfNeeded(word: composingText)
            if let c = appendBy { composingText.append(c) }
            insertText(composingText)
            return true
        }
        return false
    }
    
    private func moveCursor(offset: Int) {
        if inputEngine.isComposing {
            _ = inputEngine.moveCaret(offset: offset)
        } else {
            self.textDocumentProxy?.adjustTextPosition(byCharacterOffset: offset)
        }
    }
    
    private func handleAutoSpace() -> Bool {
        guard let textDocumentProxy = textDocumentProxy else { return false }
        
        // DDLogInfo("handleAutoSpace() hasInsertedAutoSpace \(hasInsertedAutoSpace) isLastInsertedTextFromCandidate \(isLastInsertedTextFromCandidate)")
        
        if hasInsertedAutoSpace, case .selectCandidate = lastKey {
            // Mimic iOS stock behaviour. Swallow the space tap.
            return true
        } else if hasInsertedAutoSpace || lastKey == .space,
           let last2CharsInDoc = textDocumentProxy.documentContextBeforeInput?.suffix(2),
           Settings.cached.isSmartFullStopEnabled &&
           (last2CharsInDoc.first ?? " ").couldBeFollowedBySmartSpace && last2CharsInDoc.last?.isWhitespace ?? false {
            // Translate double space tap into ". "
            textDocumentProxy.deleteBackward()
            if state.keyboardContextualType == .chinese {
                textDocumentProxy.insertText("。")
                hasInsertedAutoSpace = false
            } else {
                textDocumentProxy.insertText(". ")
                hasInsertedAutoSpace = true
            }
            return true
        }
        return false
    }
    
    private func shouldRemoveSmartSpace(_ textBeingInserted: String) -> Bool {
        guard
            // If we are inserting newline in Google Chrome address bar, do not remove smart space
            !(isTextChromeSearchBar() && textBeingInserted == "\n"),
            let textDocumentProxy = textDocumentProxy else { return false }
        
        if let last2CharsInDoc = textDocumentProxy.documentContextBeforeInput?.suffix(2),
            hasInsertedAutoSpace && last2CharsInDoc.last?.isWhitespace ?? false {
            // Remove leading smart space if:
            // English" "(中/.)
            if (last2CharsInDoc.first?.isEnglishLetterOrDigit ?? false) && !textBeingInserted.first!.isEnglishLetterOrDigit ||
                textBeingInserted == "\n" {
                // For some reason deleteBackward() does nothing unless it's wrapped in an main async block.
                // TODO Remove this.
                DDLogInfo("Should remove smart space. last2CharsInDoc '\(last2CharsInDoc)'")
                return true
            }
        }
        return false
    }
    
    private func shouldInsertSmartSpace(_ insertingText: String, _ isFromCandidateBar: Bool, _ isNewLine: Bool) -> Bool {
        guard shouldEnableSmartInput && !isNewLine,
              let textDocumentProxy = textDocumentProxy,
              let lastChar = insertingText.last else { return false }
        
        // If we are typing a url or just sent combo text like .com, do not insert smart space.
        if case .url = state.keyboardContextualType, insertingText.contains(".") { return false }
        
        // If the user is typing something like a url, do not insert smart space.
        let lastSpaceIndex = textDocumentProxy.documentContextBeforeInput?.lastIndex(where: { $0.isWhitespace })
        let lastDotIndex = textDocumentProxy.documentContextBeforeInput?.lastIndex(of: ".")
        
        guard lastDotIndex == nil ||
              // Scan the text before input from the end, if we hit a dot before hitting a space, do not insert smart space.
              lastSpaceIndex != nil && textDocumentProxy.documentContextBeforeInput?.distance(from: lastDotIndex!, to: lastSpaceIndex!) ?? 0 >= 0 else {
            // DDLogInfo("Guessing user is typing url \(textDocumentProxy.documentContextBeforeInput)")
            return false
        }
        
        
        let nextChar = textDocumentProxy.documentContextAfterInput?.first
        // Insert space after english letters and [.,;], and if the input is followed by an English letter.
        // If the input isnt from the candidate bar and there are chars following, do not insert space.
        let isTextFromCandidateBarOrCommitingAtTheEnd = isFromCandidateBar && (nextChar == nil || nextChar?.isEnglishLetter ?? false)
        let isInsertingEnglishWordBeforeEnglish = lastChar.isEnglishLetter && (nextChar?.isEnglishLetter ?? true)
        return isTextFromCandidateBarOrCommitingAtTheEnd && isInsertingEnglishWordBeforeEnglish
    }
    
    private func refreshKeyboardContextualType() {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        if textDocumentProxy.keyboardType == .some(.URL) || textDocumentProxy.keyboardType == .some(.webSearch) {
            state.keyboardContextualType = .url(isRimeComposing: inputEngine.composition?.text != nil)
        } else if inputEngine.composition?.text != nil {
            state.keyboardContextualType = .rime
        } else {
            let symbolShape = Settings.cached.symbolShape
            if symbolShape == .smart {
                // Default to English.
                guard let lastChar = textDocumentProxy.documentContextBeforeInput?.last(where: { !$0.isWhitespace }) else {
                    self.state.keyboardContextualType = .english
                    return
                }
                // If the last char is Chinese, change contextual type to Chinese.
                if lastChar.isChineseChar {
                    self.state.keyboardContextualType = .chinese
                } else {
                    self.state.keyboardContextualType = .english
                }
            } else {
                self.state.keyboardContextualType = symbolShape == .half ? .english : .chinese
            }
        }
    }
    
    private func showAutoSuggestCandidates() {        
        let textAfterInput = textDocumentProxy?.documentContextAfterInput ?? ""
        let textBeforeInput = textDocumentProxy?.documentContextBeforeInput ?? ""
        
        var newAutoSuggestionType: AutoSuggestionType?
        
        defer {
            candidateOrganizer.autoSuggestionType = newAutoSuggestionType
        }
        
        guard let lastCharBefore = textBeforeInput.last else {
            return
        }
        
        switch state.keyboardContextualType {
        case .english where !lastCharBefore.isNumber && !lastCharBefore.isPunctuation && textAfterInput.isEmpty:
            newAutoSuggestionType = .halfWidthPunctuation
        case .chinese where !lastCharBefore.isNumber && !lastCharBefore.isPunctuation && textAfterInput.isEmpty:
            newAutoSuggestionType = .fullWidthPunctuation
        case .url: ()
        default:
            if lastCharBefore.isNumber {
                if lastCharBefore.isASCII {
                    newAutoSuggestionType = .halfWidthDigit
                } else {
                    switch lastCharBefore {
                    case "０", "１", "２", "３", "４", "５", "６", "７", "８", "９":
                        newAutoSuggestionType = .fullWidthArabicDigit
                    case "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "零", "廿", "百", "千", "萬", "億":
                        newAutoSuggestionType = .fullWidthLowerDigit
                    case "壹", "貳", "叄", "肆", "伍", "陸", "柒", "捌", "玖", "拾", "佰", "仟":
                        newAutoSuggestionType = .fullWidthUpperDigit
                    default: ()
                    }
                }
            }
        }
    }
}
