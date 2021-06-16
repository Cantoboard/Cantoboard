//
//  KeyDimensions.swift
//  Stockboard
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

enum LayoutIdiom {
    case phone, pad, padFloating
}

struct LayoutConstants {
    // Fixed:
    static let keyViewTopInset = CGFloat(8)
    static let keyViewBottomInset = CGFloat(3)
    static let statusMenuRowSize = CGSize(width: 200, height: 45)
    
    // Provided:
    let idiom: LayoutIdiom
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
    let keypadButtonUnitSize: CGSize
    
    // Inferred from device constants
    // private var deviceLayoutConstants: DeviceLayoutConstants
    
    var smallKeyHintFontSize: CGFloat// { deviceLayoutConstants.smallKeyHintFontSize }
    var mediumKeyHintFontSize: CGFloat// { deviceLayoutConstants.mediumKeyHintFontSize }
    var miniStatusFontSize: CGFloat// { deviceLayoutConstants.miniStatusFontSize }
    
    var superviewSize: CGSize
    
    internal init(idiom: LayoutIdiom,
                  isPortrait: Bool,
                  keyboardSize: CGSize,
                  buttonGap: CGFloat,
                  systemKeyWidth: CGFloat,
                  shiftKeyWidth: CGFloat,
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  edgeHorizontalInset: CGFloat,
                  superviewWidth: CGFloat) {
        self.idiom = idiom
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
        
        let deviceLayoutConstants = Self.getDeviceLayoutConstants(idiom: idiom)
        smallKeyHintFontSize = deviceLayoutConstants.smallKeyHintFontSize
        mediumKeyHintFontSize = deviceLayoutConstants.mediumKeyHintFontSize
        miniStatusFontSize = deviceLayoutConstants.miniStatusFontSize
        superviewSize = CGSize(width: superviewWidth, height: keyboardSize.height)
        
        candidateFontSize = isPortrait ? deviceLayoutConstants.portraitCandidateFontSize : deviceLayoutConstants.landscapeCandidateFontSize
        candidateCommentFontSize = isPortrait ? deviceLayoutConstants.portraitCandidateCommentFontSize : deviceLayoutConstants.landscapeCandidateCommentFontSize
        candidateCharSize = "＠".size(withFont: UIFont.systemFont(ofSize: candidateFontSize))
        candidateCommentCharSize = "＠".size(withFont: UIFont.systemFont(ofSize: candidateCommentFontSize))
        statusIndicatorFontSize = isPortrait ? deviceLayoutConstants.portraitStatusIndicatorFontSize : deviceLayoutConstants.landscapeStatusIndicatorFontSize
        
        let width = (keyboardSize.width - 2 * edgeHorizontalInset - 4 * buttonGap) / 5
        let height = ((keyboardSize.height - Self.keyViewTopInset - Self.keyViewBottomInset - autoCompleteBarHeight) - 3 * buttonGap) / 4
        keypadButtonUnitSize = CGSize(width: width, height: height)
    }
    
    private static func getDeviceLayoutConstants(idiom: LayoutIdiom) -> DeviceLayoutConstants {
        switch idiom {
        case .phone: return DeviceLayoutConstants.phone
        case .pad: return DeviceLayoutConstants.pad
        case .padFloating: return DeviceLayoutConstants.padFloating
        }
    }
    
    internal static func makeiPhoneLayout(isPortrait: Bool,
                                          keyboardSize: CGSize,
                                          buttonGap: CGFloat,
                                          systemKeyWidth: CGFloat,
                                          shiftKeyWidth: CGFloat,
                                          keyHeight: CGFloat,
                                          autoCompleteBarHeight: CGFloat,
                                          edgeHorizontalInset: CGFloat,
                                          superviewWidth: CGFloat,
                                          isPadFloating: Bool = false) -> LayoutConstants {
        return LayoutConstants(
            idiom: isPadFloating ? .padFloating : .phone,
            isPortrait: isPortrait,
            keyboardSize: keyboardSize,
            buttonGap: buttonGap,
            systemKeyWidth: systemKeyWidth,
            shiftKeyWidth: shiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            edgeHorizontalInset: edgeHorizontalInset,
            superviewWidth: superviewWidth)
    }
    
    internal static func makeiPadLayout(isPortrait: Bool,
                                        keyboardWidth: CGFloat,
                                        buttonGap: CGFloat,
                                        systemKeyWidth: CGFloat,
                                        shiftKeyWidth: CGFloat,
                                        keyHeight: CGFloat,
                                        autoCompleteBarHeight: CGFloat,
                                        edgeHorizontalInset: CGFloat,
                                        superviewWidth: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            idiom: .pad,
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + buttonGap * 4 + autoCompleteBarHeight + Self.keyViewTopInset + Self.keyViewBottomInset),
            buttonGap: buttonGap,
            systemKeyWidth: systemKeyWidth,
            shiftKeyWidth: shiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            edgeHorizontalInset: edgeHorizontalInset,
            superviewWidth: superviewWidth)
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
        edgeHorizontalInset: 3,
        superviewWidth: 428),
    // Landscape:
    IntDuplet(926, 428): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 692, height: 160+38),
        buttonGap: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 3,
        superviewWidth: 926),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 390),
    // Landscape:
    IntDuplet(844, 390): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 694, height: 160+38),
        buttonGap: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 3,
        superviewWidth: 844),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 375),
    // Landscape:
    IntDuplet(812, 375): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGap: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 3,
        superviewWidth: 812),
    
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
        edgeHorizontalInset: 4,
        superviewWidth: 414),
    // Landscape:
    IntDuplet(896, 414): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGap: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 107/3,
        edgeHorizontalInset: 4,
        superviewWidth: 896),
    
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
        edgeHorizontalInset: 4,
        superviewWidth: 414),
    // Landscape:
    IntDuplet(736, 414): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 588, height: 162+38),
        buttonGap: 6,
        systemKeyWidth: 69,
        shiftKeyWidth: 69,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2,
        superviewWidth: 736),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 375),
    // Landscape:
    IntDuplet(667, 375): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 526, height: 162+38),
        buttonGap: 6,
        systemKeyWidth: 63,
        shiftKeyWidth: 63,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2,
        superviewWidth: 667),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 320),
    // Landscape:
    IntDuplet(568, 320): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 568, height: 162+38),
        buttonGap: 5,
        systemKeyWidth: 50,
        shiftKeyWidth: 68,
        keyHeight: 32,
        autoCompleteBarHeight: 36,
        edgeHorizontalInset: 2,
        superviewWidth: 568),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 1024),
    // Landscape:
    IntDuplet(1366, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1366,
        buttonGap: 9,
        systemKeyWidth: 132,
        shiftKeyWidth: 194,
        keyHeight: 80,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        superviewWidth: 1366),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 834),
    // Landscape:
    IntDuplet(1194, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1194,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 165,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        superviewWidth: 1194),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 820),
    // Landscape:
    IntDuplet(1180, 820): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1180,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 165,
        keyHeight: 73,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        superviewWidth: 1180),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 810),
    // Landscape:
    IntDuplet(1080, 810): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1080,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 155,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        superviewWidth: 1080),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 834),
    // Landscape:
    IntDuplet(1112, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1112,
        buttonGap: 11,
        systemKeyWidth: 81.5,
        shiftKeyWidth: 165,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        superviewWidth: 1112),
    
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
        edgeHorizontalInset: 3,
        superviewWidth: 768),
    // Landscape:
    IntDuplet(1024, 768): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1024,
        buttonGap: 11,
        systemKeyWidth: 77,
        shiftKeyWidth: 140,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        edgeHorizontalInset: 7,
        superviewWidth: 1024),
    
    // iPad floating mode
    IntDuplet(320, 254): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 320, height: 254),
        buttonGap: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 39,
        autoCompleteBarHeight: 38,
        edgeHorizontalInset: 3,
        superviewWidth: 320,
        isPadFloating: true),
]

extension LayoutConstants {
    static var forMainScreen: LayoutConstants {
        let traitCollection = Self.currentTraitCollection
        // DDLogInfo("iPad special mode debug UIDevice userInterfaceIdiom \(UIDevice.current.userInterfaceIdiom.rawValue)")
        // DDLogInfo("iPad special mode debug traitCollection \(traitCollection)")
        let isPadFloatingMode = UIDevice.current.userInterfaceIdiom == .pad && traitCollection.userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact
        let isPadCompatibleMode = UIDevice.current.userInterfaceIdiom == .pad && traitCollection.userInterfaceIdiom == .phone
        if isPadFloatingMode {
            // DDLogInfo("Using isPadFloatingMode")
            return getContants(screenSize: CGSize(width: 320, height: 254))
        } else if isPadCompatibleMode {
            // iPad's compatiblity mode has a bug. UIScreen doesn't return the right resolution. We canot rely on it.
            let isLandscape = UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height
            let size = isLandscape ? CGSize(width: 667, height: 375) : CGSize(width: 375, height: 667)
            // DDLogInfo("Using isPadCompatibleMode \(size)")
            return getContants(screenSize: size)
        } else {
            // DDLogInfo("Using \(UIScreen.main.bounds.size)")
            return getContants(screenSize: UIScreen.main.bounds.size)
        }
    }
    
    // Only used to workaround Apple's bug in isPadCompatibleMode.
    static var currentTraitCollection: UITraitCollection = UITraitCollection.current
    
    static func getContants(screenSize: CGSize) -> LayoutConstants {
        // TODO instead of returning an exact match, return the nearest (floorKey?) match.
        guard let ret = layoutConstantsList[IntDuplet(Int(screenSize.width), Int(screenSize.height))] else {
            DDLogInfo("Cannot find constants for (\(screenSize.width), \(screenSize.height)). Use parametric model.")
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
    
    static let phone = DeviceLayoutConstants(
        portraitCandidateFontSize: 20,
        portraitCandidateCommentFontSize: 11,
        landscapeCandidateFontSize: 20,
        landscapeCandidateCommentFontSize: 11,
        portraitStatusIndicatorFontSize: 20,
        landscapeStatusIndicatorFontSize: 15,
        smallKeyHintFontSize: 7,
        mediumKeyHintFontSize: 9,
        miniStatusFontSize: 10)
    
    static let pad = DeviceLayoutConstants(
        portraitCandidateFontSize: 28,
        portraitCandidateCommentFontSize: 15,
        landscapeCandidateFontSize: 28,
        landscapeCandidateCommentFontSize: 15,
        portraitStatusIndicatorFontSize: 25,
        landscapeStatusIndicatorFontSize: 25,
        smallKeyHintFontSize: 10,
        mediumKeyHintFontSize: 12,
        miniStatusFontSize: 12)
    
    // iPad floating mode.
    static let padFloating = DeviceLayoutConstants(
        portraitCandidateFontSize: 20,
        portraitCandidateCommentFontSize: 12,
        landscapeCandidateFontSize: 20,
        landscapeCandidateCommentFontSize: 12,
        portraitStatusIndicatorFontSize: 16,
        landscapeStatusIndicatorFontSize: 16,
        smallKeyHintFontSize: 7,
        mediumKeyHintFontSize: 7,
        miniStatusFontSize: 9)
}
