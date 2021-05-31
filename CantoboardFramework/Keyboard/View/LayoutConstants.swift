//
//  KeyDimensions.swift
//  Stockboard
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

struct LayoutConstants {
    private static let iPhonePortraitCandidateFontSize = CGFloat(22)
    private static let iPhoneLandscapeCandidateFontSize = CGFloat(20.5)
    private static let iPhonePortraitCandidateCommentFontSize = CGFloat(12)
    private static let iPhoneLandscapeCandidateCommentFontSize = CGFloat(10)
    
    private static let iPadPortraitCandidateFontSize = CGFloat(28)
    private static let iPadLandscapeCandidateFontSize = CGFloat(28)
    private static let iPadPortraitCandidateCommentFontSize = CGFloat(15)
    private static let iPadLandscapeCandidateCommentFontSize = CGFloat(15)
    
    // Fixed:
    static let keyViewTopInset = CGFloat(8)
    static let keyViewBottomInset = CGFloat(3)
    
    // Provided:
    let isPhone: Bool
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
    let statusIndicatorFontSize: CGFloat
    
    internal init(isPhone: Bool,
                  isPortrait: Bool,
                  keyboardSize: CGSize,
                  buttonGap: CGFloat,
                  systemKeyWidth: CGFloat,
                  shiftKeyWidth: CGFloat,
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  edgeHorizontalInset: CGFloat) {
        self.isPhone = isPhone
        self.keyboardSize = keyboardSize
        self.buttonGap = buttonGap
        self.edgeHorizontalInset = edgeHorizontalInset
        self.shiftButtonWidth = shiftKeyWidth
        self.systemButtonWidth = systemKeyWidth
        self.keyHeight = keyHeight
        self.autoCompleteBarHeight = autoCompleteBarHeight
        
        keyButtonWidth = (keyboardSize.width - 2 * edgeHorizontalInset - 9 * buttonGap) / 10
        keyViewHeight = keyboardSize.height - autoCompleteBarHeight - Self.keyViewTopInset - Self.keyViewBottomInset
        keyRowGap = (keyViewHeight - 4 * keyHeight) / 3
        
        let deviceLayoutConstants = DeviceLayoutConstants.forCurrentDevice
        candidateFontSize = isPortrait ? deviceLayoutConstants.portraitCandidateFontSize : deviceLayoutConstants.landscapeCandidateFontSize
        candidateCommentFontSize = isPortrait ? deviceLayoutConstants.portraitCandidateCommentFontSize : deviceLayoutConstants.landscapeCandidateCommentFontSize
        candidateCharSize = "＠".size(withFont: UIFont.systemFont(ofSize: candidateFontSize))
        candidateCommentCharSize = "＠".size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize))
        
        statusIndicatorFontSize = isPortrait ? deviceLayoutConstants.portraitStatusIndicatorFontSize : deviceLayoutConstants.landscapeStatusIndicatorFontSize
    }
    
    internal static func makeiPhoneLayout(isPortrait: Bool,
                                          keyboardSize: CGSize,
                                          buttonGap: CGFloat,
                                          systemKeyWidth: CGFloat,
                                          shiftKeyWidth: CGFloat,
                                          keyHeight: CGFloat,
                                          autoCompleteBarHeight: CGFloat,
                                          edgeHorizontalInset: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            isPhone: true,
            isPortrait: isPortrait,
            keyboardSize: keyboardSize,
            buttonGap: buttonGap,
            systemKeyWidth: systemKeyWidth,
            shiftKeyWidth: shiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            edgeHorizontalInset: edgeHorizontalInset)
    }
    
    internal static func makeiPadLayout(isPortrait: Bool,
                                        keyboardWidth: CGFloat,
                                        buttonGap: CGFloat,
                                        systemKeyWidth: CGFloat,
                                        shiftKeyWidth: CGFloat,
                                        keyHeight: CGFloat,
                                        autoCompleteBarHeight: CGFloat,
                                        edgeHorizontalInset: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            isPhone: false,
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + buttonGap * 4 + autoCompleteBarHeight + Self.keyViewTopInset + Self.keyViewBottomInset),
            buttonGap: buttonGap,
            systemKeyWidth: systemKeyWidth,
            shiftKeyWidth: shiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            edgeHorizontalInset: edgeHorizontalInset)
    }
}

let layoutConstantsList: [IntDuplet: LayoutConstants] = [
    // iPhone 12 Pro Max
    // Portrait:
    IntDuplet(428, 926): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 428, height: 175+49+45),
        buttonGap: 6,
        systemKeyWidth: 48,
        shiftKeyWidth: 47,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(926, 428): LayoutConstants.makeiPhoneLayout(
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
    IntDuplet(390, 844): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 390, height: 216+45),
        buttonGap: 6,
        systemKeyWidth: 43,
        shiftKeyWidth: 44,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(844, 390): LayoutConstants.makeiPhoneLayout(
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
    IntDuplet(375, 812): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+45),
        buttonGap: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(812, 375): LayoutConstants.makeiPhoneLayout(
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
    IntDuplet(414, 896): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGap: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 46,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 4),
    // Landscape:
    IntDuplet(896, 414): LayoutConstants.makeiPhoneLayout(
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
    IntDuplet(414, 736): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGap: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 45,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        edgeHorizontalInset: 4),
    // Landscape:
    IntDuplet(736, 414): LayoutConstants.makeiPhoneLayout(
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
    IntDuplet(375, 667): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+44),
        buttonGap: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 44,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(667, 375): LayoutConstants.makeiPhoneLayout(
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
    IntDuplet(320, 568): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 320, height: 216+38),
        buttonGap: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 38,
        autoCompleteBarHeight: 42,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(568, 320): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 568, height: 162+38),
        buttonGap: 5,
        systemKeyWidth: 50,
        shiftKeyWidth: 68,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2),
    
    // iPad 1024x1366 iPad Pro 12.9"
    // Portrait:
    IntDuplet(1024, 1366): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 1024,
        buttonGap: 7,
        systemKeyWidth: 100,
        shiftKeyWidth: 147,
        keyHeight: 62,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1366, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1366,
        buttonGap: 9,
        systemKeyWidth: 132,
        shiftKeyWidth: 194,
        keyHeight: 80,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7),
    
    // iPad 834×1194 iPad Pro 11"
    // Portrait:
    IntDuplet(834, 1194): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 834,
        buttonGap: 11,
        systemKeyWidth: 59,
        shiftKeyWidth: 115,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1194, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1194,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 165,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7),
    
    // iPad 820×1180 iPad Air (gen 4)
    // Portrait:
    IntDuplet(820, 1180): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 820,
        buttonGap: 8,
        systemKeyWidth: 59,
        shiftKeyWidth: 115,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1180, 820): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1180,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 165,
        keyHeight: 73,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7),
    
    // iPad 810×1080 iPad (gen 8/7)
    // Portrait:
    IntDuplet(810, 1080): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 810,
        buttonGap: 8,
        systemKeyWidth: 59,
        shiftKeyWidth: 110,
        keyHeight: 58,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1080, 810): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1080,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 155,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7),
    
    // iPad 834×1112 iPad Air (gen 3) iPad Pro 10.5"
    // Portrait:
    IntDuplet(834, 1112): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 834,
        buttonGap: 8,
        systemKeyWidth: 59,
        shiftKeyWidth: 115,
        keyHeight: 58,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1112, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1112,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 165,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7),
    
    // iPad 768x1024 iPad (gen 6/5/4/3/2/1) iPad Pro 9.7" iPad Air (gen 2/1) iPad mini (gen 5/4/3/2/1)
    // Portrait:
    IntDuplet(768, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 768,
        buttonGap: 8,
        systemKeyWidth: 56,
        shiftKeyWidth: 100,
        keyHeight: 56,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 3),
    // Landscape:
    IntDuplet(1024, 768): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1024,
        buttonGap: 11,
        systemKeyWidth: 77,
        shiftKeyWidth: 140,
        keyHeight: 75,
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
            DDLogInfo("Cannot find constants for (\(screenSize.width), \(screenSize.height)). Defaulting to (375, 812)")
            return layoutConstantsList.first!.value
        }
        
        return ret
    }
}

struct DeviceLayoutConstants {
    let portraitCandidateFontSize: CGFloat
    let portraitCandidateCommentFontSize: CGFloat
    
    let landscapeCandidateFontSize: CGFloat
    let landscapeCandidateCommentFontSize: CGFloat
    
    let portraitStatusIndicatorFontSize: CGFloat
    let landscapeStatusIndicatorFontSize: CGFloat
    
    let smallKeyHintFontSize: CGFloat
    let mediumKeyHintFontSize: CGFloat
    
    let miniStatusFontSize: CGFloat
    
    private static let phone = DeviceLayoutConstants(
        portraitCandidateFontSize: 22,
        portraitCandidateCommentFontSize: 12,
        landscapeCandidateFontSize: 20.5,
        landscapeCandidateCommentFontSize: 12,
        portraitStatusIndicatorFontSize: 20,
        landscapeStatusIndicatorFontSize: 15,
        smallKeyHintFontSize: 7,
        mediumKeyHintFontSize: 9,
        miniStatusFontSize: 10)
    
    private static let pad = DeviceLayoutConstants(
        portraitCandidateFontSize: 28,
        portraitCandidateCommentFontSize: 15,
        landscapeCandidateFontSize: 28,
        landscapeCandidateCommentFontSize: 15,
        portraitStatusIndicatorFontSize: 25,
        landscapeStatusIndicatorFontSize: 25,
        smallKeyHintFontSize: 10,
        mediumKeyHintFontSize: 12,
        miniStatusFontSize: 12)
    
    private static func getCurrentLayout() -> DeviceLayoutConstants {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return phone
        case .pad: return pad
        default: fatalError("Unsupported device.")
        }
    }
    static let forCurrentDevice: DeviceLayoutConstants = getCurrentLayout()
}
