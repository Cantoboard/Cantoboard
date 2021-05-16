//
//  UITextDocumentProxy+Extension.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

extension UITextDocumentProxy {
    func deleteBackwardWord() {
        guard let documentContextBeforeInput = documentContextBeforeInput,
              var lastChar = documentContextBeforeInput.last else { return }
        DDLogInfo("deleteBackwardWord documentContextBeforeInput \(documentContextBeforeInput)")
        let secondLastCharIdx = documentContextBeforeInput.index(documentContextBeforeInput.endIndex, offsetBy: -2, limitedBy: documentContextBeforeInput.startIndex) ?? documentContextBeforeInput.startIndex
        let secondLastChar = documentContextBeforeInput[safe: secondLastCharIdx]
        var deleteCount = 0
        // Cases:
        // Delete likekind.
        //   Eng:
        //     <space>English<bs> -> delete English
        //     中文English<bs> -> delete English
        //     123English<bs> -> delete English
        //   Num:
        //     <space>123<bs> -> delete 123
        //     中文123<bs> -> delete 123
        //     English123<bs> -> delete 123
        //  Space:
        //    <space><space><bs> -> delete all spaces
        // Delete 1 char.
        //   中:
        //     中文<bs> -> delete 1 char
        //   Sym:
        //     <whatever>. -> delete 1 char
        // Special case:
        //   Eng:
        //     <space>English<space><bs> -> delete English<space>
        
        let shouldDeleteLikekind = lastChar.isASCII && (lastChar.isNumber || lastChar.isLetter) || lastChar == " "
        
        if !shouldDeleteLikekind {
            // case 中 & sym.
            deleteBackward()
            return
        }
        
        // Handle special case: English<space>
        if let secondLastChar = secondLastChar, lastChar == " " && secondLastChar.isEnglishLetter {
            lastChar = secondLastChar
            deleteCount += 1
        }
        
        let reversedTextBeforeInput = documentContextBeforeInput.reversed().suffix(documentContextBeforeInput.count - deleteCount)
        // For case num & eng, find the first char from the tail that doesn't match the current type.
        let firstMismatchingCharIndex = reversedTextBeforeInput.firstIndex(where: {
            if lastChar == " " {
                return $0 != " "
            } else if lastChar.isNumber {
                return !$0.isNumber
            } else {
                return !$0.isEnglishLetter
            }
        }) ?? reversedTextBeforeInput.endIndex
        
        // Delete char between the end and the first mismatching char.
        deleteCount += reversedTextBeforeInput.distance(from: reversedTextBeforeInput.startIndex, to: firstMismatchingCharIndex)
        for _ in 0..<deleteCount {
            deleteBackward()
        }
    }
}
