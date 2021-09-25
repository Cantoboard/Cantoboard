//
//  InputBufferRenderer.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/23/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

protocol InputBufferRenderer {
    func updateInputBuffer(text: String, caretIndex: String.Index)
    func commitInputBuffer()
    func removeCharBeforeInputBuffer()
    
    var hasText: Bool { get }
    var documentContextBeforeInput: String { get }
    var documentContextAfterInput: String { get }
    
    func textReset()
}

extension InputBufferRenderer {
    func updateInputBuffer(withCaretAtTheEnd text: String) {
        updateInputBuffer(text: text, caretIndex: text.endIndex)
    }
}

class MarkedTextInputBufferRenderer: InputBufferRenderer {
    private weak var inputController: InputController?
    private(set) var hasText: Bool
    
    init(inputController: InputController?) {
        self.inputController = inputController
        self.hasText = false
    }
    
    func updateInputBuffer(text: String, caretIndex: String.Index) {
        let caretPositionInUtf16 = caretIndex.utf16Offset(in: text)
        inputController?.textDocumentProxy?.setMarkedText(text, selectedRange: NSRange(location: caretPositionInUtf16, length: 0))
        
        hasText = !text.isEmpty
    }
    
    func commitInputBuffer() {
        inputController?.textDocumentProxy?.unmarkText()
        hasText = false
    }
    
    func removeCharBeforeInputBuffer() {
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
    
    var documentContextBeforeInput: String {
        inputController?.textDocumentProxy?.documentContextBeforeInput ?? ""
    }
    
    var documentContextAfterInput: String {
        inputController?.textDocumentProxy?.documentContextAfterInput ?? ""
    }
    
    func textReset() {
        hasText = false
    }
}

class ImmediateModeInputBufferRenderer: InputBufferRenderer {
    private weak var inputController: InputController?
    private(set) var text: String
    private(set) var caretIndex: String.Index
    
    init(inputController: InputController?) {
        self.inputController = inputController
        text = ""
        caretIndex = text.endIndex
    }
    
    func updateInputBuffer(text newText: String, caretIndex newCaretIndex: String.Index) {
        guard let textDocumentProxy = inputController?.textDocumentProxy else {
            commitInputBuffer()
            return
        }
        
        guard text != newText || caretIndex != newCaretIndex else { return }
        
        let commonPrefix = text.commonPrefix(with: newText)
        
        // Remove current input buffer
        moveCaretToEnd()
        textDocumentProxy.deleteBackward(times: text.count - commonPrefix.count)
        
        // Insert input buffer
        textDocumentProxy.insertText(String(newText.suffix(newText.count - commonPrefix.count)))
        
        // Move caret
        let caretMovement = newText.distance(from: newText.endIndex, to: newCaretIndex)
        textDocumentProxy.adjustTextPosition(byCharacterOffset: caretMovement)
        
        text = newText
        caretIndex = newCaretIndex
    }
    
    func commitInputBuffer() {
        moveCaretToEnd()
        textReset()
    }
    
    func removeCharBeforeInputBuffer() {
        guard let textDocumentProxy = inputController?.textDocumentProxy else { return }
        
        // Move caret to the first char
        let caretMovement = text.distance(from: caretIndex, to: text.startIndex)
        textDocumentProxy.adjustTextPosition(byCharacterOffset: caretMovement)
        
        // Delete char
        textDocumentProxy.deleteBackward()
        
        // Restore caret position
        textDocumentProxy.adjustTextPosition(byCharacterOffset: -caretMovement)
    }
    
    private func moveCaretToEnd() {
        guard let textDocumentProxy = inputController?.textDocumentProxy else { return }
        let rightMovementCount = text.distance(from: caretIndex, to: text.endIndex)
        textDocumentProxy.adjustTextPosition(byCharacterOffset: rightMovementCount)
    }
    
    var hasText: Bool { !text.isEmpty }
    
    var documentContextBeforeInput: String {
        let documentContextBeforeInput = inputController?.textDocumentProxy?.documentContextBeforeInput ?? ""
        let inputTextBeforeCaret = text[..<caretIndex]
        if documentContextBeforeInput.hasSuffix(inputTextBeforeCaret) {
            return String(documentContextBeforeInput.prefix(documentContextBeforeInput.count - inputTextBeforeCaret.count))
        } else {
            return documentContextBeforeInput
        }
    }
    
    var documentContextAfterInput: String {
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
}
