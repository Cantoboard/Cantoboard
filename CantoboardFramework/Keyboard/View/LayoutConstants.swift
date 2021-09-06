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
    case phone, pad
}

class PhoneLayoutConstants {
    let letterKeyWidth: CGFloat
    let systemKeyWidth: CGFloat
    let shiftKeyWidth: CGFloat
    
    init(letterKeyWidth: CGFloat, systemKeyWidth: CGFloat, shiftKeyWidth: CGFloat) {
        self.letterKeyWidth = letterKeyWidth
        self.systemKeyWidth = systemKeyWidth
        self.shiftKeyWidth = shiftKeyWidth
    }
}

class PadLayoutConstants {
    let rightShiftKeyWidth: CGFloat
    let returnKeyWidth: CGFloat
    
    init(rightShiftKeyWidth: CGFloat, returnKeyWidth: CGFloat) {
        self.rightShiftKeyWidth = rightShiftKeyWidth
        self.returnKeyWidth = returnKeyWidth
    }
}

class LayoutConstants {
    // Fixed:
    static let keyboardViewTopInset = CGFloat(8)
    
    // Provided:
    // Keyboard size
    let idiom: LayoutIdiom
    let isPortrait: Bool
    let keyboardSize: CGSize
    let keyboardViewInsets: UIEdgeInsets
    
    // General
    let keyHeight: CGFloat
    let autoCompleteBarHeight: CGFloat
    
    let phoneLayoutConstants: PhoneLayoutConstants?
    let padLayoutConstants: PadLayoutConstants?
    
    // Computed:
    let keyboardViewHeight: CGFloat
    let keyboardSuperviewSize: CGSize
    
    let buttonGapX: CGFloat
    let keyRowGapY: CGFloat
    
    let keypadButtonUnitSize: CGSize
    
    var numOfSingleCharCandidateInRow: Int {
        switch idiom {
        case .phone:
            return isPortrait ? 8 : 15
        case .pad:
            return isPortrait ? 15 : 20
        }
    }
        
    internal init(idiom: LayoutIdiom,
                  isPortrait: Bool,
                  keyboardSize: CGSize,
                  buttonGapX: CGFloat,
                  systemKeyWidth: CGFloat,
                  shiftKeyWidth: CGFloat,
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  keyboardViewLeftRightInset: CGFloat,
                  keyboardViewBottomInset: CGFloat,
                  keyboardSuperviewWidth: CGFloat) {
        self.idiom = idiom
        self.isPortrait = isPortrait
        self.keyboardSize = keyboardSize
        self.buttonGapX = buttonGapX
        self.keyboardViewInsets = UIEdgeInsets(top: Self.keyboardViewTopInset, left: keyboardViewLeftRightInset, bottom: keyboardViewBottomInset, right: keyboardViewLeftRightInset)
        self.keyHeight = keyHeight
        self.autoCompleteBarHeight = autoCompleteBarHeight
        
        let letterKeyWidth = (keyboardSize.width - 2 * keyboardViewLeftRightInset - 9 * buttonGapX) / 10
        keyboardViewHeight = keyboardSize.height - autoCompleteBarHeight - Self.keyboardViewTopInset - keyboardViewBottomInset
        keyRowGapY = (keyboardViewHeight - 4 * keyHeight) / 3
        
        keyboardSuperviewSize = CGSize(width: keyboardSuperviewWidth, height: keyboardSize.height)
        
        let width = (keyboardSize.width - 2 * keyboardViewLeftRightInset - 4 * buttonGapX) / 5
        let height = ((keyboardSize.height - Self.keyboardViewTopInset - keyboardViewBottomInset - autoCompleteBarHeight) - 3 * buttonGapX) / 4
        keypadButtonUnitSize = CGSize(width: width, height: height)
        
        self.phoneLayoutConstants = idiom == .phone ? PhoneLayoutConstants(letterKeyWidth: letterKeyWidth, systemKeyWidth: systemKeyWidth, shiftKeyWidth: shiftKeyWidth) : nil
        self.padLayoutConstants = idiom == .pad ? PadLayoutConstants(rightShiftKeyWidth: shiftKeyWidth, returnKeyWidth: systemKeyWidth) : nil
    }
    
    internal static func makeiPhoneLayout(isPortrait: Bool,
                                          keyboardSize: CGSize,
                                          buttonGapX: CGFloat,
                                          systemKeyWidth: CGFloat,
                                          shiftKeyWidth: CGFloat,
                                          keyHeight: CGFloat,
                                          autoCompleteBarHeight: CGFloat,
                                          keyboardViewLeftRightInset: CGFloat,
                                          keyboardSuperviewWidth: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            idiom: .phone,
            isPortrait: isPortrait,
            keyboardSize: keyboardSize,
            buttonGapX: buttonGapX,
            systemKeyWidth: systemKeyWidth,
            shiftKeyWidth: shiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            keyboardViewLeftRightInset: keyboardViewLeftRightInset,
            keyboardViewBottomInset: 4,
            keyboardSuperviewWidth: keyboardSuperviewWidth)
    }
    
    internal static func makeiPadLayout(isPortrait: Bool,
                                        keyboardWidth: CGFloat,
                                        buttonGapX: CGFloat,
                                        rowGapY: CGFloat,
                                        returnKeyWidth: CGFloat,
                                        rightShiftKeyWidth: CGFloat,
                                        keyHeight: CGFloat,
                                        autoCompleteBarHeight: CGFloat,
                                        keyboardViewLeftRightInset: CGFloat,
                                        keyboardViewBottomInset: CGFloat,
                                        keyboardSuperviewWidth: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            idiom: .pad,
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + rowGapY * 3 + autoCompleteBarHeight + Self.keyboardViewTopInset + keyboardViewBottomInset),
            buttonGapX: buttonGapX,
            systemKeyWidth: returnKeyWidth,
            shiftKeyWidth: rightShiftKeyWidth,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            keyboardViewLeftRightInset: keyboardViewLeftRightInset,
            keyboardViewBottomInset: keyboardViewBottomInset,
            keyboardSuperviewWidth: keyboardSuperviewWidth)
    }
}

let layoutConstantsList: [IntDuplet: LayoutConstants] = [
    // iPhone 12 Pro Max
    // Portrait:
    IntDuplet(428, 926): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 428, height: 175+49+45),
        buttonGapX: 6,
        systemKeyWidth: 48,
        shiftKeyWidth: 47,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 428),
    // Landscape:
    IntDuplet(926, 428): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 692, height: 160+38),
        buttonGapX: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 926),
    
    // iPhone 12, 12 Pro
    // Portrait:
    IntDuplet(390, 844): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 390, height: 216+45),
        buttonGapX: 6,
        systemKeyWidth: 43,
        shiftKeyWidth: 44,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 390),
    // Landscape:
    IntDuplet(844, 390): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 694, height: 160+38),
        buttonGapX: 5,
        systemKeyWidth: 62,
        shiftKeyWidth: 84,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 844),
    
    // iPhone 12 mini, 11 Pro, X, Xs
    // Portrait:
    IntDuplet(375, 812): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+45),
        buttonGapX: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 375),
    // Landscape:
    IntDuplet(812, 375): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGapX: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 812),
    
    // iPhone 11 Pro Max, Xs Max, 11, Xr
    // Portrait:
    IntDuplet(414, 896): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGapX: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 46,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 4,
        keyboardSuperviewWidth: 414),
    // Landscape:
    IntDuplet(896, 414): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 662, height: 150+38),
        buttonGapX: 5,
        systemKeyWidth: 59,
        shiftKeyWidth: 80,
        keyHeight: 30,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 896),
    
    // iPhone 8+, 7+, 6s+, 6+
    // Portrait:
    IntDuplet(414, 736): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 414, height: 226+45),
        buttonGapX: 6,
        systemKeyWidth: 46,
        shiftKeyWidth: 45,
        keyHeight: 45,
        autoCompleteBarHeight: 45,
        keyboardViewLeftRightInset: 4,
        keyboardSuperviewWidth: 414),
    // Landscape:
    IntDuplet(736, 414): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 588, height: 162+38),
        buttonGapX: 6,
        systemKeyWidth: 69,
        shiftKeyWidth: 69,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 2,
        keyboardSuperviewWidth: 736),
    
    // iPhone SE (2nd gen), 8, 7, 6s, 6
    // Portrait:
    IntDuplet(375, 667): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 375, height: 216+44),
        buttonGapX: 6,
        systemKeyWidth: 40,
        shiftKeyWidth: 42,
        keyHeight: 42,
        autoCompleteBarHeight: 44,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 375),
    // Landscape:
    IntDuplet(667, 375): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 526, height: 162+38),
        buttonGapX: 6,
        systemKeyWidth: 63,
        shiftKeyWidth: 63,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 667),
    
    // iPhone SE (1st gen), 5c, 5s, 5
    // Portrait:
    IntDuplet(320, 568): LayoutConstants.makeiPhoneLayout(
        isPortrait: true,
        keyboardSize: CGSize(width: 320, height: 216+38),
        buttonGapX: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 38,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 320),
    // Landscape:
    IntDuplet(568, 320): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 568, height: 162+38),
        buttonGapX: 5,
        systemKeyWidth: 50,
        shiftKeyWidth: 68,
        keyHeight: 32,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 568),
    
    // iPad 1024x1366 iPad Pro 12.9"
    // Portrait:
    IntDuplet(1024, 1366): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 1024,
        buttonGapX: 7,
        rowGapY: 7,
        returnKeyWidth: 100,
        rightShiftKeyWidth: 147,
        keyHeight: 62,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 3,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 1024),
    // Landscape:
    IntDuplet(1366, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1366,
        buttonGapX: 9,
        rowGapY: 9,
        returnKeyWidth: 132,
        rightShiftKeyWidth: 194,
        keyHeight: 80,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 7,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 1366),
    
    // iPad 834×1194 iPad Pro 11"
    // Portrait:
    IntDuplet(834, 1194): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 834,
        buttonGapX: 11,
        rowGapY: 11,
        returnKeyWidth: 59,
        rightShiftKeyWidth: 115,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 3,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 834),
    // Landscape:
    IntDuplet(1194, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1194,
        buttonGapX: 11,
        rowGapY: 11,
        returnKeyWidth: 81.5,
        rightShiftKeyWidth: 165,
        keyHeight: 75,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 7,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 1194),
    
    // iPad 820×1180 iPad Air (gen 4) 10.9"
    // Portrait:
    IntDuplet(820, 1180): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 820,
        buttonGapX: 8,
        rowGapY: 8,
        returnKeyWidth: 59,
        rightShiftKeyWidth: 115,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 3,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 820),
    // Landscape:
    IntDuplet(1180, 820): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1180,
        buttonGapX: 11,
        rowGapY: 11,
        returnKeyWidth: 81.5,
        rightShiftKeyWidth: 165,
        keyHeight: 73,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 7,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 1180),
    
    // iPad 810×1080 iPad (gen 8/7) 10.2"
    // Portrait:
    IntDuplet(810, 1080): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 810,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 112.5,
        rightShiftKeyWidth: 81,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 6,
        keyboardViewBottomInset: 8,
        keyboardSuperviewWidth: 810),
    // Landscape:
    IntDuplet(1080, 810): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1080,
        buttonGapX: 14.5,
        rowGapY: 12,
        returnKeyWidth: 152,
        rightShiftKeyWidth: 111.5,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 7,
        keyboardViewBottomInset: 10,
        keyboardSuperviewWidth: 1080),
    
    // iPad 834×1112 iPad Air (gen 3) iPad Pro 10.5"
    // Portrait:
    IntDuplet(834, 1112): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 834,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 115.5,
        rightShiftKeyWidth: 83,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 6.5,
        keyboardViewBottomInset: 8,
        keyboardSuperviewWidth: 834),
    // Landscape:
    IntDuplet(1112, 834): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1112,
        buttonGapX: 14.5,
        rowGapY: 12,
        returnKeyWidth: 156.5,
        rightShiftKeyWidth: 114.5,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 7.5,
        keyboardViewBottomInset: 10,
        keyboardSuperviewWidth: 1112),
    
    // iPad 768x1024 iPad (gen 6/5/4/3/2/1) iPad Pro 9.7" iPad Air (gen 2/1) iPad mini (gen 5/4/3/2/1) 7.9"
    // Portrait:
    IntDuplet(768, 1024): LayoutConstants.makeiPadLayout(
        isPortrait: true,
        keyboardWidth: 768,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 106,
        rightShiftKeyWidth: 76,
        keyHeight: 55,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 6,
        keyboardViewBottomInset: 8,
        keyboardSuperviewWidth: 768),
    // Landscape:
    IntDuplet(1024, 768): LayoutConstants.makeiPadLayout(
        isPortrait: false,
        keyboardWidth: 1024,
        buttonGapX: 12,
        rowGapY: 9,
        returnKeyWidth: 144,
        rightShiftKeyWidth: 105,
        keyHeight: 74,
        autoCompleteBarHeight: 55,
        keyboardViewLeftRightInset: 7,
        keyboardViewBottomInset: 10,
        keyboardSuperviewWidth: 1024),
    
    // iPad floating mode
    IntDuplet(320, 254): LayoutConstants.makeiPhoneLayout(
        isPortrait: false,
        keyboardSize: CGSize(width: 320, height: 254),
        buttonGapX: 6,
        systemKeyWidth: 34,
        shiftKeyWidth: 36,
        keyHeight: 39,
        autoCompleteBarHeight: 38,
        keyboardViewLeftRightInset: 3,
        keyboardSuperviewWidth: 320),
]

extension LayoutConstants {
    static var forMainScreen: LayoutConstants {
        return getContants(screenSize: UIScreen.main.bounds.size)
    }
    
    static func getContants(screenSize: CGSize) -> LayoutConstants {
        // TODO instead of returning an exact match, return the nearest (floorKey?) match.
        guard let ret = layoutConstantsList[IntDuplet(Int(screenSize.width), Int(screenSize.height))] else {
            DDLogInfo("Cannot find constants for (\(screenSize.width), \(screenSize.height)).")
            return layoutConstantsList.first!.value
        }
        
        return ret
    }
}
