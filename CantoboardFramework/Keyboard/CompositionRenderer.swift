//
//  InputBufferRenderer.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/23/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

protocol CompositionRenderer {
    func update(text: String, caretIndex: String.Index)
    func commit()
    func removeCharBeforeInput() // For removing smart space before input.
    
    var hasText: Bool { get }
    var textBeforeInput: String { get }
    var textAfterInput: String { get }
    
    func textReset()
}

extension CompositionRenderer {
    func update(withCaretAtTheEnd text: String) {
        update(text: text, caretIndex: text.endIndex)
    }
    
    func clear() {
        if hasText {
            update(withCaretAtTheEnd: "")
            commit()
        }
    }
}

class MarkedTextCompositionRenderer: CompositionRenderer {
    private weak var inputController: InputController?
    private(set) var hasText: Bool
    
    init(inputController: InputController?) {
        self.inputController = inputController
        self.hasText = false
    }
    
    func update(text: String, caretIndex: String.Index) {
        let caretPositionInUtf16 = caretIndex.utf16Offset(in: text)
        inputController?.textDocumentProxy?.setMarkedText(text, selectedRange: NSRange(location: caretPositionInUtf16, length: 0))
        
        hasText = !text.isEmpty
    }
    
    func commit() {
        inputController?.textDocumentProxy?.unmarkText()
        hasText = false
    }
    
    func removeCharBeforeInput() {
        guard let textDocumentProxy = inputController?.textDocumentProxy else { return }
        // If there's marked text, we've to make an extra call to deleteBackward to remove the marked text before we could delete the space.
        if hasText {
            textDocumentProxy.deleteBackward()
            // If we hit this case, textDocumentProxy.documentContextBeforeInput will no longer be in-sync with the text of the document,
            // It will contain part of the marked text which the doc doesn't contain.
            // Fortunately, contextual update looks at the tail of the documentContextBeforeInput only.
            // After inserting text, the inaccurate text doesn't affect the contextual update.
        }
        textDocumentProxy.deleteBackward()
    }
    
    var textBeforeInput: String {
        inputController?.textDocumentProxy?.documentContextBeforeInput ?? ""
    }
    
    var textAfterInput: String {
        inputController?.textDocumentProxy?.documentContextAfterInput ?? ""
    }
    
    func textReset() {
        hasText = false
    }
    
    deinit {
        clear()
    }
}

class ImmediateModeCompositionRenderer: CompositionRenderer {
    private weak var inputController: InputController?
    private(set) var text: String
    private(set) var caretIndex: String.Index
    
    init(inputController: InputController?) {
        self.inputController = inputController
        text = ""
        caretIndex = text.endIndex
    }
    
    func update(text newText: String, caretIndex newCaretIndex: String.Index) {
        // Adjusting text position too frequent in textbox with auto completion
        // would cause textDocumentProxy going out sync with the actual text in the textbox.
        // For example: Slack, search box on www.youtube.com in WKWebView.
        // The following line keeps the system caret at the end of the composition to workaround the limitation.
        let newCaretIndex = newText.endIndex
        
        guard let textDocumentProxy = inputController?.textDocumentProxy else {
            commit()
            return
        }
        
        guard text != newText || caretIndex != newCaretIndex else { return }
        
        // Remove the previous composition, then insert the new one.
        let commonPrefix = text.commonPrefix(with: newText)
        
        // Remove current input buffer
        let deleteCount = text.count - commonPrefix.count
        if deleteCount > 0 {
            moveCaretToEnd()
            textDocumentProxy.deleteBackward(times: deleteCount)
        }
        
        // Insert input buffer
        let insertText = String(newText.suffix(newText.count - commonPrefix.count))
        if !insertText.isEmpty {
            textDocumentProxy.insertText(insertText)
        }
        
        // Move caret
        let caretMovement = newText.distance(from: newText.endIndex, to: newCaretIndex)
        if caretMovement != 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: caretMovement)
        }
        
        text = newText
        caretIndex = newCaretIndex
    }
    
    func commit() {
        moveCaretToEnd()
        textReset()
    }
    
    func removeCharBeforeInput() {
        guard let textDocumentProxy = inputController?.textDocumentProxy else { return }
        
        // Originally, I implemented this as adjustTextPosition(n), deleteBackward() then adjustTextPosition(-n)
        // Turned out it doesn't work well on Slack (textbox with autocomplete)
        // The following code is less efficient but compatible with Slack:
        
        let numCharsToDelete = text.distance(from: text.startIndex, to: caretIndex)
        textDocumentProxy.deleteBackward(times: numCharsToDelete + 1)
        
        textDocumentProxy.insertText(String(text.prefix(upTo: caretIndex)))
    }
    
    private func moveCaretToEnd() {
        guard let textDocumentProxy = inputController?.textDocumentProxy else { return }
        let rightMovementCount = text.distance(from: caretIndex, to: text.endIndex)
        textDocumentProxy.adjustTextPosition(byCharacterOffset: rightMovementCount)
    }
    
    var hasText: Bool { !text.isEmpty }
    
    var textBeforeInput: String {
        let documentContextBeforeInput = inputController?.textDocumentProxy?.documentContextBeforeInput ?? ""
        let inputTextBeforeCaret = text[..<caretIndex]
        if documentContextBeforeInput.hasSuffix(inputTextBeforeCaret) {
            return String(documentContextBeforeInput.prefix(documentContextBeforeInput.count - inputTextBeforeCaret.count))
        } else {
            return documentContextBeforeInput
        }
    }
    
    var textAfterInput: String {
        let documentContextAfterInput = inputController?.textDocumentProxy?.documentContextAfterInput ?? ""
        let inputTextAfterCaret = text[caretIndex...]
        if documentContextAfterInput.hasPrefix(inputTextAfterCaret) {
            return String(documentContextAfterInput.suffix(documentContextAfterInput.count - inputTextAfterCaret.count))
        } else {
            return documentContextAfterInput
        }
    }
    
    func textReset() {
        text = ""
        caretIndex = text.endIndex
    }
    
    deinit {
        clear()
    }
}
