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

enum KeyboardEnableState: Equatable {
    case enabled, disabled, loading
}

enum ContextualType: Equatable {
    case english, chinese, rime, url
    
    var isEnglish: Bool {
        switch self {
        case .english, .rime, .url: return true
        default: return false
        }
    }
}

struct KeyboardState: Equatable {
    var keyboardType: KeyboardType {
        didSet {
            if case .alphabetic = keyboardType {
                symbolShapeOverride = nil
            }
        }
    }
    var lastKeyboardTypeChangeFromAutoCap: Bool
    var isComposing: Bool
    var keyboardContextualType: ContextualType
    var symbolShapeOverride: SymbolShape?
    var isPortrait: Bool
    
    var enableState: KeyboardEnableState
    
    var returnKeyType: ReturnKeyType
    var needsInputModeSwitchKey: Bool
    var spaceKeyMode: SpaceKeyMode
    
    var keyboardIdiom: LayoutIdiom
    
    var mainSchema: RimeSchema, reverseLookupSchema: RimeSchema?
    var inputMode: InputMode {
        didSet { SessionState.main.lastInputMode = inputMode }
    }
    
    var activeSchema: RimeSchema {
        get { reverseLookupSchema ?? mainSchema }
    }
    
    var symbolShape: SymbolShape {
        symbolShapeOverride ?? (keyboardContextualType == .chinese ? .full : .half)
    }
    
    init() {
        keyboardType = KeyboardType.alphabetic(.lowercased)
        lastKeyboardTypeChangeFromAutoCap = false
        isComposing = false
        keyboardContextualType = .english
        let layoutConstants = LayoutConstants.forMainScreen
        keyboardIdiom = layoutConstants.idiom
        isPortrait = layoutConstants.isPortrait
        
        enableState = .enabled
        
        returnKeyType = .default
        needsInputModeSwitchKey = false
        spaceKeyMode = .space
        
        mainSchema = SessionState.main.lastPrimarySchema
        inputMode = SessionState.main.lastInputMode
    }
}

class InputController: NSObject {
    private weak var keyboardViewController: KeyboardViewController?
    private weak var keyboardView: BaseKeyboardView?
    private(set) var inputEngine: BilingualInputEngine!
    private var compositionRenderer: CompositionRenderer!
    private(set) var isImmediateMode: Bool!
    
    private(set) var state: KeyboardState = KeyboardState()
    
    private var lastKey: KeyboardAction?
    private var isHoldingShift = false
        
    private var hasInsertedAutoSpace = false
    private var shouldApplyChromeSearchBarHack = false
    private var needClearInput = false, needReloadCandidates = true
    
    private var prevTextBefore: String?
    
    private(set) var candidateOrganizer: CandidateOrganizer!
    
    var textDocumentProxy: UITextDocumentProxy? {
        keyboardViewController?.textDocumentProxy
    }
    
    private var documentContextBeforeInput: String {
        compositionRenderer.textBeforeInput
    }
    
    private var documentContextAfterInput: String {
        compositionRenderer.textAfterInput
    }
    
    init(keyboardViewController: KeyboardViewController) {
        super.init()
        
        self.keyboardViewController = keyboardViewController
        inputEngine = BilingualInputEngine(inputController: self, rimeSchema: state.mainSchema)
        candidateOrganizer = CandidateOrganizer(inputController: self)
        
        initKeyboardView()
        refreshInputSettings()
    }
    
    private var shouldUseKeypad: Bool {
        if state.activeSchema == .stroke, case .alphabetic = state.keyboardType, state.inputMode != .english {
            return true
        }
        return false
    }
    
    private func reinitInputViewIfNeeded() {
        if shouldUseKeypad && keyboardView is KeyboardView ||
            !shouldUseKeypad && keyboardView is KeypadView {
            keyboardView?.removeFromSuperview()
            initKeyboardView()
        }
    }
    
    private func initKeyboardView() {
        guard let keyboardViewController = keyboardViewController,
              let keyboardViewPlaceholder = keyboardViewController.keyboardViewPlaceholder else { return }
        let keyboardView: BaseKeyboardView
        if shouldUseKeypad {
            keyboardView = KeypadView(state: state, candidateOrganizer: candidateOrganizer, layoutConstants: keyboardViewController.layoutConstants)
        } else {
            keyboardView = KeyboardView(state: state, candidateOrganizer: candidateOrganizer, layoutConstants: keyboardViewController.layoutConstants)
        }
        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardViewPlaceholder.addSubview(keyboardView)
        
        NSLayoutConstraint.activate([
            keyboardView.leftAnchor.constraint(equalTo: keyboardViewPlaceholder.leftAnchor),
            keyboardView.rightAnchor.constraint(equalTo: keyboardViewPlaceholder.rightAnchor),
            keyboardView.topAnchor.constraint(equalTo: keyboardViewPlaceholder.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: keyboardViewPlaceholder.bottomAnchor),
        ])
        
        self.keyboardView = keyboardView
    }
    
    deinit {
        keyboardView?.removeFromSuperview()
    }
    
    func textWillChange(_ textInput: UITextInput?) {
        prevTextBefore = compositionRenderer.textBeforeInput
        // DDLogInfo("textWillChange prevTextBefore '\(prevTextBefore ?? "nil")' doc '\(textDocumentProxy?.documentContextBeforeInput ?? "nil")'")
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        // DDLogInfo("textDidChange prevTextBefore '\(prevTextBefore ?? "nil")' textBeforeInput '\(compositionRenderer.textBeforeInput)' doc '\(textDocumentProxy?.documentContextBeforeInput ?? "nil")'")
        shouldApplyChromeSearchBarHack = isTextFieldWebSearch() && !isImmediateMode
        
        let textBeforeInput = compositionRenderer.textBeforeInput
        if !isImmediateMode && isTextFieldWebSearch() && prevTextBefore != textBeforeInput && !textBeforeInput.isEmpty {
            // Attempt to fix https://github.com/Cantoboard/Cantoboard/issues/33
            // !textBeforeInput.isEmpty is added to fix address typing in Chrome. Without this fix, the first input letter is ignored.
            clearInput()
            prevTextBefore = textBeforeInput
        }
        
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
            insertText(commitedText, requestSmartSpace: enableSmartSpace)
            if !candidateOrganizer.shouldCloseCandidatePaneOnCommit {
                keyboardView?.changeCandidatePaneMode(.row)
            }
        }
    }
    
    private func candidateLongPressed(choice: IndexPath) {
        if let text = candidateOrganizer.getCandidate(indexPath: choice), text.allSatisfy({ $0.isEnglishLetter }) {
            if EnglishInputEngine.userDictionary.unlearnWord(word: text) {
                FeedbackProvider.lightImpact.impactOccurred()
                let candidateCount = candidateOrganizer.getCandidateCount(section: choice.section)
                inputEngine.updateEnglishCandidates()
                candidateOrganizer.updateCandidates(reload: true, targetCandidatesCount: candidateCount)
            }
        }
    }
    
    private func handleSpace(spaceKeyMode: SpaceKeyMode) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        let hasCandidate = inputEngine.isComposing && candidateOrganizer.getCandidateCount(section: 0) > 0
        switch spaceKeyMode {
        case .nextPage where hasCandidate:
            keyboardView?.scrollCandidatePaneToNextPageInRowMode()
            needReloadCandidates = false
        case .select where hasCandidate:
            candidateSelected(choice: [0, 0], enableSmartSpace: true)
        default:
            if !insertComposingText() {
                if !handleAutoSpace() {
                    textDocumentProxy.insertText(" ")
                }
            }
        }
    }
    
    private func handleQuote(isDoubleQuote: Bool) {
        let openingChar: Character = isDoubleQuote ? "“" : "‘"
        let closingChar: Character = isDoubleQuote ? "”" : "’"

        let textBeforeInput: String
        if inputEngine.isComposing {
            textBeforeInput = documentContextBeforeInput + (inputEngine.composition?.text ?? "")
        } else {
            textBeforeInput = documentContextBeforeInput
        }

        let lastOpenCharIndex = textBeforeInput.lastIndex(of: openingChar)
        let lastClosingCharIndex = textBeforeInput.lastIndex(of: closingChar)

        let quote: String
        if keyboardViewController?.textDocumentProxy.smartQuotesType ?? .default == .no {
            quote = isDoubleQuote ? "\"" : "'"
        } else if !isDoubleQuote && !(textBeforeInput.last?.isWhitespace ?? true) {
            // iOS default keyboard uses right single quote as apostrophe
            quote = String(closingChar)
        } else if lastOpenCharIndex != nil && lastClosingCharIndex == nil {
            // prev context has just opening quote.
            quote = String(closingChar)
        } else if
            let lastOpenCharIndex = lastOpenCharIndex,
            let lastClosingCharIndex = lastClosingCharIndex,
            textBeforeInput.distance(from: lastClosingCharIndex, to: lastOpenCharIndex) > 0 {
            // prev context has opening quotes & closing quotes.
            quote = String(closingChar)
        } else {
            quote = String(openingChar)
        }

        if !insertComposingText(appendBy: quote) {
            insertText(quote)
        }
    }
    
    private var cachedActions: [KeyboardAction] = []
    
    func reenableKeyboard() {
        DispatchQueue.main.async { [self] in
            guard RimeApi.shared.state == .succeeded else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: reenableKeyboard)
                return
            }
            DDLogInfo("Enabling keyboard.")
            cachedActions.forEach({ self.handleKey($0) })
            cachedActions = []
            state.enableState = .enabled
            keyboardView?.state = state
        }
    }
    
    func keyboardDisappeared() {
        compositionRenderer.textReset()
        clearInput()
    }
    
    func onLayoutChanged() {
        guard let newLayoutConstants = keyboardViewController?.layoutConstants.ref else { return }
        state.keyboardIdiom = newLayoutConstants.idiom
        state.isPortrait = newLayoutConstants.isPortrait

        keyboardView?.state = state
    }
    
    func handleKey(_ action: KeyboardAction) {
        guard RimeApi.shared.state == .succeeded else {
            // If RimeEngine isn't ready, disable the keyboard.
            DDLogInfo("Disabling keyboard")
            state.enableState = .loading
            cachedActions.append(action)
            keyboardView?.state = state
            return
        }
        
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        defer {
            lastKey = action
            reinitInputViewIfNeeded()
            keyboardView?.state = state
        }
        
        needClearInput = false
        needReloadCandidates = true
        let isComposing = inputEngine.isComposing
        
        switch action {
        case .moveCursorForward, .moveCursorBackward:
            moveCursor(offset: action == .moveCursorBackward ? -1 : 1)
        case .character(let c):
            guard let char = c.first else { return }
            if !isComposing && shouldApplyChromeSearchBarHack {
                // To clear out the current url selected in Chrome address bar.
                // This shouldn't have any side effects in other apps.
                textDocumentProxy.insertText("")
            }
            let shouldFeedCharToInputEngine = char.isEnglishLetter && c.count == 1
            if !(shouldFeedCharToInputEngine && inputEngine.processChar(char)) {
                if !insertComposingText(appendBy: c) {
                    insertText(c)
                }
            }
            if !isHoldingShift && state.keyboardType == .some(.alphabetic(.uppercased)) {
                state.keyboardType = .alphabetic(.lowercased)
                state.lastKeyboardTypeChangeFromAutoCap = false
            }
        case .rime(let rc):
            guard isComposing || rc == .sym else { return }
            _ = inputEngine.processRimeChar(rc.rawValue)
        case .space(let spaceKeyMode):
            handleSpace(spaceKeyMode: spaceKeyMode)
        case .quote(let isDoubleQuote):
            handleQuote(isDoubleQuote: isDoubleQuote)
        case .newLine:
            if !insertComposingText(shouldDisableSmartSpace: true) || isImmediateMode {
                let shouldApplyBrowserYoutubeSearchHack = textDocumentProxy.returnKeyType == .search && !isImmediateMode
                if shouldApplyBrowserYoutubeSearchHack {
                    // This is a special hack for triggering finishing/search event with marked text in browser searching on www.youtube.com
                    textDocumentProxy.unmarkText()
                    DispatchQueue.main.async {
                        textDocumentProxy.insertText("\n")
                    }
                } else {
                    insertText("\n")
                }
            }
        case .backspace, .deleteWord, .deleteWordSwipe:
            if state.reverseLookupSchema != nil && !isComposing {
                clearInput(shouldLeaveReverseLookupMode: true)
            } else if isComposing {
                if action == .deleteWordSwipe {
                    needClearInput = true
                } else {
                    if isTextFieldWebSearch() && isImmediateMode {
                        // To clear out the auto complete suggestion in Chrome url bar.
                        // Without this hack, deleteBackward() call will only remove the autosuggestion. It won't remove the the last char of the input.
                        // This shouldn't have any side effects in other apps.
                        textDocumentProxy.insertText(" ")
                        textDocumentProxy.deleteBackward()
                    }
                    _ = inputEngine.processBackspace()
                }
                if !inputEngine.isComposing {
                    keyboardView?.changeCandidatePaneMode(.row)
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
            FeedbackProvider.play(keyboardAction: action)
            if !insertComposingText(appendBy: e, shouldDisableSmartSpace: true) {
                textDocumentProxy.insertText(e)
            }
        case .shiftDown:
            isHoldingShift = true
            state.keyboardType = .alphabetic(.uppercased)
            state.lastKeyboardTypeChangeFromAutoCap = false
            return
        case .shiftUp:
            state.keyboardType = .alphabetic(.lowercased)
            state.lastKeyboardTypeChangeFromAutoCap = false
            isHoldingShift = false
            return
        case .shiftRelax:
            isHoldingShift = false
            return
        case .keyboardType(let type):
            state.keyboardType = type
            state.lastKeyboardTypeChangeFromAutoCap = false
            self.checkAutoCap()
            return
        case .setCharForm(let cs):
            inputEngine.charForm = cs
            let currentCandidatesCount = candidateOrganizer.getCandidateCount(section: 0)
            keyboardView?.setPreserveCandidateOffset()
            candidateOrganizer.updateCandidates(reload: true, targetCandidatesCount: currentCandidatesCount)
            return
        case .toggleInputMode:
            guard state.reverseLookupSchema == nil else {
                // Disable reverse look up mode on tap.
                state.reverseLookupSchema = nil
                changeSchema()
                return
            }
            
            state.inputMode = state.inputMode.afterToggle
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
            changeSchema()
            SessionState.main.lastPrimarySchema = schema
            return
        case .selectCandidate(let choice):
            candidateSelected(choice: choice, enableSmartSpace: true)
        case .longPressCandidate(let choice):
            candidateLongPressed(choice: choice)
        case .exportFile(let namePrefix, let path):
            state.enableState = .loading
            keyboardView?.state = state
            
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
                    state.enableState = .enabled
                    keyboardView?.state = state
                }
            }
        case .enableKeyboard(let e):
            state.enableState = e ? .enabled : .disabled
            keyboardView?.state = state
        case .dismissKeyboard:
            keyboardViewController?.dismissKeyboard()
        case .resetComposition:
            compositionRenderer.textReset()
            needClearInput = true
        case .exit: exit(0)
        default: ()
        }
        if needClearInput {
            clearInput()
        } else {
            updateInputState()
        }
        updateComposition()
    }
    
    func refreshInputSettings() {
        if Settings.cached.isMixedModeEnabled && state.inputMode == .chinese { state.inputMode = .mixed }
        if !Settings.cached.isMixedModeEnabled && state.inputMode == .mixed { state.inputMode = .chinese }
        
        isImmediateMode =  Settings.cached.compositionMode == .immediate
        if isImmediateMode {
            if !(compositionRenderer is ImmediateModeCompositionRenderer) {
                compositionRenderer = ImmediateModeCompositionRenderer(inputController: self)
            }
        } else {
            if !(compositionRenderer is MarkedTextCompositionRenderer) {
                compositionRenderer = MarkedTextCompositionRenderer(inputController: self)
            }
        }
        
        keyboardViewController?.hasCompositionView = isImmediateMode || state.activeSchema.isCangjieFamily && state.inputMode == .mixed
        keyboardViewController?.hasCompositionResetButton = isImmediateMode && state.isComposing
    }
    
    func isTextFieldWebSearch() -> Bool {
        guard let textFieldType = textDocumentProxy?.keyboardType else { return false }
        // DDLogInfo("isTextChromeSearchBar \(textFieldType) \(textDocumentProxy?.documentContextBeforeInput ?? "<empty-documentContextBeforeInput>")")
        // Finding: documentContextBeforeInput might not contain the full url.
        return textFieldType == UIKeyboardType.webSearch
    }
    
    private func shouldApplyAutoCap() -> Bool {
        guard let textDocumentProxy = textDocumentProxy else { return false }
        //print("autocapitalizationType", textDocumentProxy.autocapitalizationType?.rawValue)
        if textDocumentProxy.autocapitalizationType == .some(.none) ||
            inputEngine.isComposing ||
            isHoldingShift
            { return false }
        
        // There are three cases we should apply auto cap:
        // - First char in the doc. nil
        // - Half shaped: e.g. ". " -> "<sym><space>"
        // - Full shaped: e.g. "。" -> "<sym>"
        let documentContextBeforeInput = documentContextBeforeInput
        let lastChar = documentContextBeforeInput.last
        let lastSymbol = documentContextBeforeInput.last(where: { $0 != " " })
        // DDLogInfo("documentContextBeforeInput \(documentContextBeforeInput) \(lastChar)")
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
        state.lastKeyboardTypeChangeFromAutoCap = true
    }
    
    private func changeSchema() {
        inputEngine.rimeSchema = state.activeSchema
        if state.inputMode == .english {
            handleKey(.toggleInputMode)
        }
        clearInput(shouldLeaveReverseLookupMode: false)
    }
    
    private func clearInput(shouldLeaveReverseLookupMode: Bool = true) {
        inputEngine.clearInput()
        if shouldLeaveReverseLookupMode {
            state.reverseLookupSchema = nil
            inputEngine.rimeSchema = state.activeSchema
        }
        updateInputState()
        updateComposition()
    }
    
    private func insertText(_ text: String, requestSmartSpace: Bool = false) {
        guard !text.isEmpty else { return }
        guard let textDocumentProxy = textDocumentProxy else { return }
        let isNewLine = text == "\n"
        
        if shouldRemoveSmartSpace(text) {
            compositionRenderer.removeCharBeforeInput()
            hasInsertedAutoSpace = false
        }
        
        var textToBeInserted: String
        
        if shouldInsertSmartSpace(text, requestSmartSpace, isNewLine) {
            textToBeInserted = text + " "
            hasInsertedAutoSpace = true
        } else {
            textToBeInserted = text
            hasInsertedAutoSpace = false
        }
        
        // After countless attempt, this provides the best compatibility.
        // Test cases:
        // Normal text fields
        // Safari/Chrome searching on www.youtube.com, enter should trigger search. Requires a special hack when inserting "\n".
        // Chrome address bar, entering the first character should clear out the current url.
        // GMail search field.
        // Google Calender create event title text field
        // Twitter search bar: enter 𥄫女 (𥄫 is a multiple codepoints char)
        // Slack
        // Number only text field, keyboard should be able to insert multiple digits.
        if compositionRenderer.hasText {
            // Calling setMarkedText("") & unmarkText() here won't work in Slack. It will insert the text twice.
            compositionRenderer.update(withCaretAtTheEnd: textToBeInserted)
            compositionRenderer.commit()
        } else {
            textDocumentProxy.insertText(textToBeInserted)
        }
        
        needClearInput = true
        // DDLogInfo("insertText() hasInsertedAutoSpace \(hasInsertedAutoSpace) isLastInsertedTextFromCandidate \(isLastInsertedTextFromCandidate)")
    }
    
    private func updateInputState() {
        updateContextualSuggestion()
        candidateOrganizer.updateCandidates(reload: needReloadCandidates)
        
        let isComposing = inputEngine.isComposing
        state.returnKeyType = isComposing && !isImmediateMode ? .confirm : ReturnKeyType(textDocumentProxy?.returnKeyType ?? .default)
        state.needsInputModeSwitchKey = keyboardViewController?.needsInputModeSwitchKey ?? false
        if !isComposing || state.inputMode == .english {
            state.spaceKeyMode = .space
        } else {
            let hasCandidate = isComposing && candidateOrganizer.getCandidateCount(section: 0) > 0
            switch Settings.cached.spaceAction {
            case .nextPage where hasCandidate: state.spaceKeyMode = .nextPage
            case .insertCandidate where hasCandidate: state.spaceKeyMode = .select
            default: state.spaceKeyMode = .space
            }
        }
        state.isComposing = isComposing
        keyboardView?.state = state
    }
    
    private func updateComposition() {
        switch state.inputMode {
        case .chinese: updateComposition(inputEngine.composition)
        case .english: updateComposition(inputEngine.englishComposition)
        case .mixed:
            if state.activeSchema.isCangjieFamily {
                // Show both Cangjie radicals and english composition in marked text.
                // let composition = inputEngine.rimeComposition
                // composition?.text += " " + (inputEngine.englishComposition?.text ?? "")
                // updateComposition(composition)
                updateComposition(inputEngine.englishComposition)
            } else {
                updateComposition(inputEngine.composition)
            }
        }
        
        if state.activeSchema.isCangjieFamily {
            keyboardViewController?.compositionLabelView?.composition = inputEngine.rimeComposition
        } else {
            keyboardViewController?.compositionLabelView?.composition = inputEngine.composition
        }
        refreshInputSettings()
    }
    
    private func updateComposition(_ composition: Composition?) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        guard var text = composition?.text, !text.isEmpty else {
            if compositionRenderer.hasText {
                compositionRenderer.update(withCaretAtTheEnd: "")
                compositionRenderer.commit()
            }
            return
        }
        var caretPosition = composition?.caretIndex ?? NSNotFound
        
        let inputType = textDocumentProxy.keyboardType ?? .default
        let shouldStripSpace = inputType == .URL || inputType == .emailAddress || inputType == .webSearch || isImmediateMode
        if shouldStripSpace {
            let spaceStrippedSpace = text.filter { $0 != " " }
            caretPosition -= text.prefix(caretPosition).reduce(0, { $0 + ($1 != " " ? 0 : 1) })
            text = spaceStrippedSpace
        }
        
        compositionRenderer.update(text: text, caretIndex: text.index(text.startIndex, offsetBy: caretPosition))
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
            if state.inputMode == .english || state.inputMode == .mixed && composingText.first?.isEnglishLetter ?? false {
                composingText = englishText
            } else if inputEngine.rimeSchema == .jyutping && Settings.cached.toneInputMode == .vxq {
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
            insertText(composingText, requestSmartSpace: !shouldDisableSmartSpace)
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
        let last2CharsInDoc = documentContextBeforeInput.suffix(2)
        if hasInsertedAutoSpace, case .selectCandidate = lastKey {
            // Mimic iOS stock behaviour. Swallow the space tap.
            return true
        } else if (hasInsertedAutoSpace || lastKey?.isSpace ?? false) &&
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
        // If we are inserting newline in Google Chrome address bar, do not remove smart space
        guard !(isTextFieldWebSearch() && textBeingInserted == "\n") else { return false }
        
        let documentContextBeforeInput = documentContextBeforeInput
        let last2CharsInDoc = documentContextBeforeInput.suffix(2)
        
        // Always keep smart space if quotes are being inserted
        if textBeingInserted.first?.isOpeningQuote ?? false {
            return false
        }
        
        if hasInsertedAutoSpace && last2CharsInDoc.last?.isWhitespace ?? false {
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
              let lastChar = insertingText.last else { return false }
        
        // If we are typing a url or just sent combo text like .com, do not insert smart space.
        if case .url = state.keyboardContextualType, insertingText.contains(".") { return false }
        
        // If the user is typing something like a url, do not insert smart space.
        let documentContextBeforeInput = documentContextBeforeInput
        let lastSpaceIndex = documentContextBeforeInput.lastIndex(where: { $0.isWhitespace })
        let lastDotIndex = documentContextBeforeInput.lastIndex(of: ".")
        
        guard lastDotIndex == nil ||
              // Scan the text before input from the end, if we hit a dot before hitting a space, do not insert smart space.
              lastSpaceIndex != nil && documentContextBeforeInput.distance(from: lastDotIndex!, to: lastSpaceIndex!) >= 0 else {
            // DDLogInfo("Guessing user is typing url \(textDocumentProxy.documentContextBeforeInput)")
            return false
        }
        
        
        let nextChar = documentContextAfterInput.first
        // Insert space after english letters and [.,;], and if the input is followed by an English letter.
        // If the input isnt from the candidate bar and there are chars following, do not insert space.
        let isTextFromCandidateBarOrCommitingAtTheEnd = isFromCandidateBar && (nextChar == nil || nextChar?.isEnglishLetter ?? false)
        let isInsertingEnglishWordBeforeEnglish = lastChar.isEnglishLetter && (nextChar?.isEnglishLetter ?? true)
        return isTextFromCandidateBarOrCommitingAtTheEnd && isInsertingEnglishWordBeforeEnglish
    }
    
    private func refreshKeyboardContextualType() {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        if textDocumentProxy.keyboardType == .some(.URL) || textDocumentProxy.keyboardType == .some(.webSearch) {
            state.keyboardContextualType = .url
        } else if inputEngine.composition?.text != nil {
            state.keyboardContextualType = .rime
        } else {
            let symbolShape = Settings.cached.symbolShape
            if symbolShape == .smart {
                // Default to English.
                guard let lastChar = documentContextBeforeInput.last(where: { !$0.isWhitespace }) else {
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
        let textBeforeInput = documentContextBeforeInput
        let textAfterInput = documentContextAfterInput
        
        var newAutoSuggestionType: AutoSuggestionType?
        
        defer {
            candidateOrganizer.autoSuggestionType = newAutoSuggestionType
        }
        
        guard let lastCharBefore = textBeforeInput.last else {
            return
        }
        
        switch lastCharBefore {
        case "@":
            newAutoSuggestionType = .email
            return
        case "." where
            keyboardViewController?.textDocumentProxy.keyboardType == .URL ||
            keyboardViewController?.textDocumentProxy.keyboardType == .webSearch:
            newAutoSuggestionType = .domain
            return
        default: ()
        }
        
        switch state.keyboardContextualType {
        case .english where !lastCharBefore.isNumber && lastCharBefore.isLetter && textAfterInput.isEmpty:
            newAutoSuggestionType = .halfWidthPunctuation
        case .chinese where !lastCharBefore.isNumber && lastCharBefore.isLetter && textAfterInput.isEmpty:
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

extension InputController: KeyboardViewDelegate {
    func handleInputModeList(from: UIView, with: UIEvent) {
        keyboardViewController?.handleInputModeList(from: from, with: with)
    }
}
