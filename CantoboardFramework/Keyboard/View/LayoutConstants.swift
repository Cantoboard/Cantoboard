//
//  KeyDimensions.swift
//  Stockboard
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

struct LayoutConstants {
    private static let portraitCandidateFontSize = CGFloat(22), landscapeCandidateFontSize = CGFloat(20.5)
    private static let portraitCandidateCommentFontSize = CGFloat(12), landscapeCandidateCommentFontSize = CGFloat(10)
    
    // Fixed:
    let keyViewTopInset = CGFloat(8)
    let keyViewBottomInset = CGFloat(3)
    
    // Provided:
    let keyboardSize: CGSize
    let keyButtonWidth: CGFloat
    let systemButtonWidth: CGFloat
    let shiftButtonWidth: CGFloat
    let keyHeight: CGFloat
    let autoCompleteBarHeight: CGFloat
    let edgeHorizontalInset: CGFloat
    
    // Computed:
    let buttonGap: CGFloat
    let keyViewHeight: CGFloat
    let keyRowGap: CGFloat
    let candidateFontSize: CGFloat
    let candidateCharSize: CGSize
    let candidateCommentFontSize: CGFloat
    let candidateCommentCharSize: CGSize
    
    internal init(isPortrait: Bool,
                  keyboardSize: CGSize,
                  buttonGap: CGFloat,
                  systemKeyWidth: CGFloat,
                  shiftKeyWidth: CGFloat,
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  edgeHorizontalInset: CGFloat) {
        self.keyboardSize = keyboardSize
        self.buttonGap = buttonGap
        self.edgeHorizontalInset = edgeHorizontalInset
        self.shiftButtonWidth = shiftKeyWidth
        self.systemButtonWidth = systemKeyWidth
        self.keyHeight = keyHeight
        self.autoCompleteBarHeight = autoCompleteBarHeight
        
        keyButtonWidth = (keyboardSize.width - 2 * edgeHorizontalInset - 9 * buttonGap) / 10
        keyViewHeight = keyboardSize.height - autoCompleteBarHeight - keyViewTopInset - keyViewBottomInset
        keyRowGap = (keyViewHeight - 4 * keyHeight) / 3
        
        candidateFontSize = isPortrait ? Self.portraitCandidateFontSize : Self.landscapeCandidateFontSize
        candidateCommentFontSize = isPortrait ? Self.portraitCandidateCommentFontSize : Self.landscapeCandidateCommentFontSize
        candidateCharSize = "＠".size(withFont: UIFont.systemFont(ofSize: candidateFontSize))
        candidateCommentCharSize = "＠".size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize))
    }
}

let layoutConstantsList: [IntDuplet: LayoutConstants] = [
    // iPhone 12 Pro Max
    // Portrait:
    IntDuplet(428, 926): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 428, height: 175+49+45),
        buttonGap: 6,
        systemKeyWidth: 48,
        shiftKeyWidth: 47,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(926, 428): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 692, height: 160+38),
        buttonGap: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 3),
    
    // iPhone 12, 12 Pro
    // Portrait:
    IntDuplet(390, 844): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 390, height: 216+45),
        buttonGap: 6,
        systemKeyWidth: 43,
        shiftKeyWidth: 44,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(844, 390): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 694, height: 160+38),
        buttonGap: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 3),
    
    // iPhone 12 mini, 11 Pro, X, Xs
    // Portrait:
    IntDuplet(375, 812): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+45),
        buttonGap: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(812, 375): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGap: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 3),
    
    // iPhone 11 Pro Max, Xs Max, 11, Xr
    // Portrait:
    IntDuplet(414, 896): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGap: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 46,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 4),
    // Landscape:
    IntDuplet(896, 414): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGap: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 107/3,
        edgeHorizontalInset: 4),
    
    // iPhone 8+, 7+, 6s+, 6+
    // Portrait:
    IntDuplet(414, 736): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGap: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 45,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 4),
    // Landscape:
    IntDuplet(736, 414): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 588, height: 162+38),
        buttonGap: 6,
        systemKeyWidth: 69,
        shiftKeyWidth: 69,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2),
    
    // iPhone SE (2nd gen), 8, 7, 6s, 6
    // Portrait:
    IntDuplet(375, 667): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+44),
        buttonGap: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 44,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(667, 375): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 526, height: 162+38),
        buttonGap: 6,
        systemKeyWidth: 63,
        shiftKeyWidth: 63,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2),
    
    // iPhone SE (1st gen), 5c, 5s, 5
    // Portrait:
    IntDuplet(320, 568): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 320, height: 216+38),
        buttonGap: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 38,
        autoCompleteBarHeight: 42,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(568, 320): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 568, height: 162+38),
        buttonGap: 5,
        systemKeyWidth: 50,
        shiftKeyWidth: 68,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2),
    
    // iPad 768x1024
    // Portrait:
    IntDuplet(768, 1024): LayoutConstants(
        isPortrait: true,
        keyboardSize: CGSize(width: 768, height: 258+55),
        buttonGap: 12,
        systemKeyWidth: 56,
        shiftKeyWidth: 56,
        keyHeight: 57,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1024, 768): LayoutConstants(
        isPortrait: false,
        keyboardSize: CGSize(width: 1024, height: 353+55),
        buttonGap: 14,
        systemKeyWidth: 77,
        shiftKeyWidth: 77,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7),
]

extension LayoutConstants {
    static var forMainScreen: LayoutConstants {
        getContants(screenSize: UIScreen.main.bounds.size)
    }
    
    static func getContants(screenSize: CGSize) -> LayoutConstants {
        // TODO instead of returning an exact match, return the nearest (floorKey?) match.
        guard let ret = layoutConstantsList[IntDuplet(Int(screenSize.width), Int(screenSize.height))] else {
            NSLog("Cannot find constants for (%f, %f). Defaulting to (375, 812)", screenSize.width, screenSize.height)
            return layoutConstantsList.first!.value
        }
        
        return ret
    }
}
