//
//  InputHandler.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/26/21.
//

import Foundation
import UIKit

enum ContextualType: Equatable {
    case english, chinese, rime, url(isRimeComposing: Bool)
}

class InputController {
    private weak var keyboardViewController: KeyboardViewController?
    private let inputEngine: BilingualInputEngine
    private var hasInsertedAutoSpace = false
    private var isLastInsertedTextFromCandidate = false
    private var shouldApplyChromeSearchBarHack = false, shouldSkipNextTextDidChange = false
    private var lastKey: (KeyboardAction, Date)?
    private var isHoldingShift = false
    private var prevTextBefore: String?
    
    private var keyboardType = KeyboardType.alphabetic(.lowercased) {
        didSet {
            keyboardView?.keyboardType = keyboardType
        }
    }
    
    private var keyboardContextualType: ContextualType = .english {
        didSet {
            keyboardView?.keyboardContextualType = keyboardContextualType
        }
    }
    
    private var textDocumentProxy: UITextDocumentProxy? {
        keyboardViewController?.textDocumentProxy
    }
    
    private var keyboardView: KeyboardView? {
        keyboardViewController?.keyboardView
    }
    
    init(keyboardViewController: KeyboardViewController) {
        self.keyboardViewController = keyboardViewController
        inputEngine = BilingualInputEngine(textDocumentProxy: keyboardViewController.textDocumentProxy)
    }
    
    func textWillChange(_ textInput: UITextInput?) {
        prevTextBefore = textDocumentProxy?.documentContextBeforeInput
        // NSLog("textWillChange \(prevTextBefore)")
    }
    
    func textDidChange(_ textInput: UITextInput?) {
        // NSLog("textDidChange prevTextBefore \(prevTextBefore) documentContextBeforeInput \(textDocumentProxy?.documentContextBeforeInput)")
        shouldApplyChromeSearchBarHack = isTextChromeSearchBar()
        if prevTextBefore != textDocumentProxy?.documentContextBeforeInput && !shouldSkipNextTextDidChange {
            clearState()
        } else if let composition = inputEngine.composition, !shouldApplyChromeSearchBarHack {
            self.setMarkedText(composition)
        }
        
        shouldSkipNextTextDidChange = false
        
        DispatchQueue.main.async {
            self.checkAutoCap()
            self.refreshKeyboardContextualType()
        }
    }
    
    func candidateSelected(_ choice: Int) {
        AudioFeedbackProvider.Play(keyboardAction: .character(""))
        
        if let commitedText = inputEngine.selectCandidate(choice) {
            setMarkedText(nil)
            insertText(commitedText)
            isLastInsertedTextFromCandidate = true
        } else {
            updateInputState()
        }
        lastKey = nil
    }
    
    func keyPressed(_ action: KeyboardAction) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        guard RimeApi.shared.state == .succeeded else {
            // If RimeEngine isn't ready, disable the keyboard.
            NSLog("Disabling keyboard")
            keyboardView?.isEnabled = false
            return
        }
        
        switch action {
        case .moveCursorForward, .moveCursorBackward:
            moveCursor(offset: action == .moveCursorBackward ? -1 : 1)
        case .character(let c):
            guard let char = c.first else { return }
            if inputEngine.composition == nil && shouldApplyChromeSearchBarHack {
                DispatchQueue.main.async {
                    self.shouldSkipNextTextDidChange = true
                    textDocumentProxy.insertText("")
                }
            }
            let shouldFeedCharToInputEngine = char.isASCII && char.isLetter && c.count == 1
            if shouldFeedCharToInputEngine && inputEngine.processChar(char) {
                updateInputState()
            } else {
                if !insertComposingText(appendBy: c) {
                    insertText(c)
                }
            }
            if !isHoldingShift && keyboardType == .some(.alphabetic(.uppercased)) {
                keyboardType = .alphabetic(.lowercased)
            }
        case .rime(let rc):
            guard inputEngine.composition != nil else { return }
            if inputEngine.processRimeChar(rc.rawValue) {
                updateInputState()
            }
        case .space:
            if !insertComposingText() {
                if !handleSpaceTap() {
                    textDocumentProxy.insertText(" ")
                    DispatchQueue.main.async {
                        self.checkAutoCap()
                    }
                }
            }
        case .newLine:
            _ = insertComposingText()
            DispatchQueue.main.async {
                if self.isTextChromeSearchBar() {
                    self.textDocumentProxy?.insertText("\n")
                } else {
                    self.insertText("\n")
                }
            }
        case .backspace, .deleteWord:
            if inputEngine.composition?.text != nil {
                if inputEngine.processBackspace() {
                    updateInputState()
                }
            } else {
                if action == .backspace {
                    textDocumentProxy.deleteBackward()
                } else {
                    textDocumentProxy.deleteBackwardWord()
                }
            }
            DispatchQueue.main.async {
                self.checkAutoCap()
            }
        case .emoji(let e):
            AudioFeedbackProvider.Play(keyboardAction: action)
            textDocumentProxy.insertText(e)
        case .shiftDown:
            isHoldingShift = true
            keyboardType = .alphabetic(.uppercased)
        case .shiftUp:
            keyboardType = .alphabetic(.lowercased)
            isHoldingShift = false
        case .shiftRelax:
            isHoldingShift = false
        case .keyboardType(let type):
            keyboardType = type
            DispatchQueue.main.async {
                self.checkAutoCap()
            }
            return
        case .setChineseScript(let cs):
            Settings.shared.chineseScript = cs
            inputEngine.refreshChineseScript()
            updateInputState()
            return
        default:
            ()
        }
        lastKey = (action, Date())
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
        // NSLog("documentContextBeforeInput \(textDocumentProxy.documentContextBeforeInput) \(lastChar)")
        let isFirstCharInDoc = lastChar == nil
        let isHalfShapedCase = (lastChar?.isWhitespace ?? false && lastSymbol?.isSentensePunctuation ?? false)
        let isFullShapedCase = lastChar?.isFullShapeSentensePunctuation ?? false
        return isFirstCharInDoc || isHalfShapedCase || isFullShapedCase
    }
    
    private func checkAutoCap() {
        guard !isHoldingShift &&
              (keyboardType == .alphabetic(.lowercased) || keyboardType == .alphabetic(.uppercased))
            else { return }
        keyboardType = shouldApplyAutoCap() ? .alphabetic(.uppercased) : .alphabetic(.lowercased)
    }
    
    private func clearInput() {
        inputEngine.clearInput()
        updateInputState()
    }
    
    func clearState() {
        clearInput()
        hasInsertedAutoSpace = false
        isLastInsertedTextFromCandidate = false
        shouldSkipNextTextDidChange = false
        lastKey = nil
        prevTextBefore = nil
    }
    
    private func insertText(_ text: String) {
        guard !text.isEmpty else { return }
        clearInput()
        
        // We must let the message loop to handle previously entered text first.
        // Queue the following steps to the main thread.
        DispatchQueue.main.async {
            self.tryRemoveSmartSpace(text)
            // tryRemoveSmartSpace might mutate the text.
            // We have to wrap the following insert text in an async block to not step over tryRemoveSmartSpace.
            DispatchQueue.main.async {
                guard let textDocumentProxy = self.textDocumentProxy else { return }
                
                textDocumentProxy.insertText(text)
                if self.shouldEnableSmartInput {
                    self.tryInsertSmartSpace(text)
                }
                self.refreshKeyboardContextualType()
                self.checkAutoCap()
            }
        }
    }
    
    private func updateInputState() {
        setMarkedText(inputEngine.composition)
        
        DispatchQueue.main.async {
            let candidates = self.inputEngine.getCandidates()
            self.keyboardView?.candidateSource = CandidateSource(candidates: candidates, requestMoreCandidate: self.inputEngine.loadMoreCandidates)
        }
        
        refreshKeyboardContextualType()
    }
    
    private func setMarkedText(_ composition: Composition?) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        var text = composition?.text ?? ""
        var caretPosition = composition?.caretIndex ?? NSNotFound
        
        let inputType = textDocumentProxy.keyboardType ?? .default
        let shouldStripSpace = inputType == .URL || inputType == .emailAddress || inputType == .webSearch
        if shouldStripSpace {
            let spaceStrippedSpace = text.filter { $0 != " " }
            caretPosition -= text.prefix(caretPosition).reduce(0, { $0 + ($1 != " " ? 0 : 1) })
            text = spaceStrippedSpace
        }
        
        DispatchQueue.main.async {
            textDocumentProxy.setMarkedText(text, selectedRange: NSRange(location: caretPosition, length: 0))
            if text == "" { textDocumentProxy.unmarkText() }
        }
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
    
    private func insertComposingText(appendBy: String? = nil) -> Bool {
        if var composingText = inputEngine.composition?.text.filter({ $0 != " " }),
           !composingText.isEmpty {
            if let c = appendBy { composingText.append(c) }
            insertText(composingText)
            isLastInsertedTextFromCandidate = false
            return true
        }
        return false
    }
    
    private func moveCursor(offset: Int) {
        if inputEngine.composition?.text != nil {
            if inputEngine.moveCaret(offset: offset) { updateInputState() }
        } else {
            DispatchQueue.main.async {
                self.textDocumentProxy?.adjustTextPosition(byCharacterOffset: offset)
                DispatchQueue.main.async {
                    self.checkAutoCap()
                }
            }
        }
    }
    
    private func handleSpaceTap() -> Bool {
        guard let textDocumentProxy = textDocumentProxy else { return false }
        
        if hasInsertedAutoSpace && isLastInsertedTextFromCandidate {
            // Mimic the behaviour of stock iOS keyboard.
            // Selecting a candidate in the stock keyboard inserts the word followed with a space.
            // If the user taps space right after, that space tap is ignored.
            hasInsertedAutoSpace = false
            return true
        } else if lastKey?.0 == .some(.space),
           let last2CharsInDoc = textDocumentProxy.documentContextBeforeInput?.suffix(2),
           last2CharsInDoc.first?.isLetter ?? false && last2CharsInDoc.last?.isWhitespace ?? false {
            // Translate double space tap into ". "
            DispatchQueue.main.async {
                textDocumentProxy.deleteBackward()
                if self.keyboardContextualType == .chinese {
                    textDocumentProxy.insertText("。")
                } else {
                    textDocumentProxy.insertText(". ")
                }
                self.hasInsertedAutoSpace = false
                self.checkAutoCap()
            }
            return true
        }
        return false
    }
    
    private func tryRemoveSmartSpace(_ textAfter: String) {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        if let last2CharsInDoc = textDocumentProxy.documentContextBeforeInput?.suffix(2),
            hasInsertedAutoSpace && last2CharsInDoc.last?.isWhitespace ?? false {
            // Remove leading smart space if:
            // English" "(中/.)
            if (last2CharsInDoc.first?.isEnglishLetter ?? false) && textAfter.first!.isChineseChar ||
               (last2CharsInDoc.first?.isLetter ?? false) && textAfter.first!.isSentensePunctuation {
                // For some reason deleteBackward() does nothing unless it's wrapped in an main async block.
                DispatchQueue.main.async {
                    textDocumentProxy.deleteBackward()
                    self.hasInsertedAutoSpace = false
                }
            }
        }
    }
    
    private func tryInsertSmartSpace(_ lastInput: String) {
        guard let textDocumentProxy = textDocumentProxy,
              let lastChar = lastInput.last else { return }
        
        // If we are typing a url or just sent combo text like .com, do not insert smart space.
        if case .url = keyboardContextualType, lastInput.contains(".") { return }
        
        // If the user is typing something like a url, do not insert smart space.
        let lastSpaceIndex = textDocumentProxy.documentContextBeforeInput?.lastIndex(where: { $0.isWhitespace })
        let lastDotIndex = textDocumentProxy.documentContextBeforeInput?.lastIndex(of: ".")
        
        guard lastDotIndex == nil ||
              // Scan the text before input from the end, if we hit a dot before hitting a space, do not insert smart space.
              lastSpaceIndex != nil && textDocumentProxy.documentContextBeforeInput?.distance(from: lastDotIndex!, to: lastSpaceIndex!) ?? 0 >= 0 else {
            // NSLog("Guessing user is typing url \(textDocumentProxy.documentContextBeforeInput)")
            return
        }
        
        
        let nextChar = textDocumentProxy.documentContextAfterInput?.first
        // Insert space after english letters and [.,;], and if the input is followed by an English letter.
        // If the input isnt from the candidate bar and there are chars following, do not insert space.
        if (isLastInsertedTextFromCandidate || nextChar == nil) &&
            lastChar.isEnglishLetter && (nextChar?.isEnglishLetter ?? true) {
            textDocumentProxy.insertText(" ")
            hasInsertedAutoSpace = true
            checkAutoCap()
        }
    }
    
    private func refreshKeyboardContextualType() {
        guard let textDocumentProxy = textDocumentProxy else { return }
        
        if textDocumentProxy.keyboardType == .some(.URL) || textDocumentProxy.keyboardType == .some(.webSearch) {
            keyboardContextualType = .url(isRimeComposing: inputEngine.composition?.text != nil)
        } else if inputEngine.composition?.text != nil {
            keyboardContextualType = .rime
        } else {
            DispatchQueue.main.async {
                if Settings.shared.symbolShape == .smart {
                    // Default to English.
                    guard let lastChar = textDocumentProxy.documentContextBeforeInput?.last(where: { !$0.isWhitespace }) else {
                        self.keyboardContextualType = .english
                        return
                    }
                    // If the last char is Chinese, change contextual type to Chinese.
                    if lastChar.isChineseChar {
                        self.keyboardContextualType = .chinese
                    } else {
                        self.keyboardContextualType = .english
                    }
                } else {
                    self.keyboardContextualType = Settings.shared.symbolShape == .half ? .english : .chinese
                }
            }
        }
    }
}
