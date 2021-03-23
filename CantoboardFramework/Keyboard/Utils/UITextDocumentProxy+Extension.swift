//
//  UITextDocumentProxy+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

extension UITextDocumentProxy {
    func deleteBackwardWord() {
        guard let documentContextBeforeInput = documentContextBeforeInput, !documentContextBeforeInput.isEmpty else { return }
        var lastWhitespaceIndex: String.Index?
        if documentContextBeforeInput.last!.isNumber {
            lastWhitespaceIndex = documentContextBeforeInput.lastIndex { !$0.isNumber }
            if lastWhitespaceIndex != nil {
                lastWhitespaceIndex = documentContextBeforeInput.index(after: lastWhitespaceIndex!)
            }
        } else {
            lastWhitespaceIndex = documentContextBeforeInput.lastIndex { $0.isWhitespace || $0.isPunctuation }
        }
        let deleteCount = documentContextBeforeInput.distance(from: lastWhitespaceIndex ?? documentContextBeforeInput.startIndex, to: documentContextBeforeInput.endIndex)
        for _ in 0..<deleteCount {
            deleteBackward()
        }
    }
}
