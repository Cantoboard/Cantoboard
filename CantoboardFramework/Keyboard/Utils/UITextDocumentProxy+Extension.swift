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
        guard let documentContextBeforeInput = documentContextBeforeInput else { return }
        let lastWhitespaceIndex = documentContextBeforeInput.lastIndex { $0.isWhitespace || $0.isSentensePunctuation } ?? documentContextBeforeInput.startIndex
        let deleteCount = documentContextBeforeInput.distance(from: lastWhitespaceIndex, to: documentContextBeforeInput.endIndex)
        for _ in 0..<deleteCount {
            deleteBackward()
        }
    }
}
