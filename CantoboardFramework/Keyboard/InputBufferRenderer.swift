//
//  InputBufferRenderer.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/23/21.
//

import Foundation
import UIKit

protocol InputBufferRenderer {
    func updateInputBuffer(text: String, caretIndex: String.Index)
    func commitInputBuffer()
    var hasText: Bool { get }
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
}
