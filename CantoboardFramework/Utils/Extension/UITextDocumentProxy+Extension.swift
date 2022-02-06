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
    func deleteBackward(times: Int) {
        guard times >= 0 else { return }
        for _ in 0..<times {
            deleteBackward()
        }
    }
    
    func deleteBackwardWord(retry: Bool = true) {
        DispatchQueue.main.async { [self] in
            guard let string = documentContextBeforeInput else {
                // In case if documentContextBeforeInput goes out of sync, fallback to delete single char.
                deleteBackward()
                if retry {
                    DispatchQueue.main.async { // Another async is required for the code to run properly
                        deleteBackwardWord(retry: false)
                    }
                }
                return
            }
            
            // Delete CCC, CCW, CW, WCC, WC, WW where C is an ideograph and W is a sequence of letters. Ignore whitespaces and non-letter characters.
            var index = string.endIndex
            var next: Bool!
            var ideographCount = 0
            let isApostrophe: () -> Bool = {
                guard let prevIndex = string.index(index, offsetBy: -1, limitedBy: string.startIndex),
                      let nextIndex = string.index(index, offsetBy: 1, limitedBy: string.endIndex) else { return false }
                return string[prevIndex].isLetterLike && string[index].isApostrophe && string[nextIndex].isLetterLike
            }
            let prev = {
                next = string.formIndex(&index, offsetBy: -1, limitedBy: string.startIndex)
            }
            let eatWhitespace = {
                while next && string[index].isWhitespace { prev() }
            }
            let eatNonLetterLike = {
                while next && string[index].isNonLetterLike { prev() }
            }
            let eatLetterLike = {
                while next && string[index].isLetterLike || isApostrophe() { prev() }
            }
            let eatSpace = {
                while next && string[index].isSpace { prev() }
            }
            let eatIdeograph = {
                while next && string[index].isIdeographic && ideographCount < 3 {
                    ideographCount += 1
                    prev()
                }
            }
            
            prev()
            eatWhitespace()
            eatNonLetterLike()
            eatIdeograph()
            if ideographCount < 3 {
                if ideographCount == 0 {
                    eatLetterLike()
                }
                eatNonLetterLike()
                eatWhitespace()
                eatNonLetterLike()
                let oldIdeographCount = ideographCount
                eatIdeograph()
                if oldIdeographCount == ideographCount {
                    eatLetterLike()
                }
            }
            eatSpace()
            
            if next {
                next = string.formIndex(&index, offsetBy: 1, limitedBy: string.endIndex)
            }
            // Delete at least one character in case if documentContextBeforeInput goes out of sync.
            deleteBackward(times: max(1, string.distance(from: index, to: string.endIndex)))
        }
    }
}
