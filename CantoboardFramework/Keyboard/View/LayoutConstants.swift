//
//  KeyDimensions.swift
//  Stockboard
//
//  Created by Alex Man on 1/14/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

enum PadLayoutIdiom {
    case padShort, padFull4Rows, padFull5Rows
}

enum LayoutIdiom: Equatable {
    case phone, pad(PadLayoutIdiom)
    
    var isPad: Bool {
        switch self {
        case .phone: return false
        case .pad: return true
        }
    }
    
    var isPadFull: Bool {
        switch self {
        case .pad(.padFull4Rows), .pad(.padFull5Rows): return true
        default: return false
        }
    }
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

class PadShortLayoutConstants {
    let rightShiftKeyWidth: CGFloat
    let returnKeyWidth: CGFloat
    
    init(rightShiftKeyWidth: CGFloat, returnKeyWidth: CGFloat) {
        self.rightShiftKeyWidth = rightShiftKeyWidth
        self.returnKeyWidth = returnKeyWidth
    }
}

class PadFull4RowsLayoutConstants {
    let tabDeleteKeyWidth: CGFloat
    
    let capLockKeyWidth: CGFloat
    let leftShiftKeyWidth: CGFloat
    let smallSystemKeyWidth: CGFloat
    
    let returnKeyWidth: CGFloat
    let rightShiftKeyWidth: CGFloat
    let largeSystemKeyWidth: CGFloat
    
    init(tabDeleteKeyWidth: CGFloat,
         capLockKeyWidth: CGFloat, leftShiftKeyWidth: CGFloat, smallSystemKeyWidth: CGFloat,
         returnKeyWidth: CGFloat, rightShiftKeyWidth: CGFloat, largeSystemKeyWidth: CGFloat) {
        self.tabDeleteKeyWidth = tabDeleteKeyWidth
        
        self.capLockKeyWidth = capLockKeyWidth
        self.leftShiftKeyWidth = leftShiftKeyWidth
        self.smallSystemKeyWidth = smallSystemKeyWidth
        
        self.returnKeyWidth = returnKeyWidth
        self.rightShiftKeyWidth = rightShiftKeyWidth
        self.largeSystemKeyWidth = largeSystemKeyWidth
    }
}

class PadFull5RowsLayoutConstants {
    let topRowKeyHeight: CGFloat
    
    let tabKeyWidth: CGFloat
    let capLockKeyWidth: CGFloat
    let leftShiftKeyWidth: CGFloat
    let smallSystemKeyWidth: CGFloat
    
    let deleteKeyWidth: CGFloat
    let returnKeyWidth: CGFloat
    let rightShiftKeyWidth: CGFloat
    let largeSystemKeyWidth: CGFloat
    
    init(topRowKeyHeight: CGFloat,
         tabKeyWidth: CGFloat, capLockKeyWidth: CGFloat, leftShiftKeyWidth: CGFloat, smallSystemKeyWidth: CGFloat,
         deleteKeyWidth: CGFloat, returnKeyWidth: CGFloat, rightShiftKeyWidth: CGFloat, largeSystemKeyWidth: CGFloat) {
        self.topRowKeyHeight = topRowKeyHeight
        
        self.tabKeyWidth = tabKeyWidth
        self.capLockKeyWidth = capLockKeyWidth
        self.leftShiftKeyWidth = leftShiftKeyWidth
        self.smallSystemKeyWidth = smallSystemKeyWidth
        
        self.deleteKeyWidth = deleteKeyWidth
        self.returnKeyWidth = returnKeyWidth
        self.rightShiftKeyWidth = rightShiftKeyWidth
        self.largeSystemKeyWidth = largeSystemKeyWidth
    }
}

class LayoutConstants {
    // Fixed:
    static let keyboardViewTopInset = CGFloat(8)
    private static let contentEdgeInsetsPhone = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    private static let contentEdgeInsetsPadShortAndFull = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6 )
    private static let contentEdgeInsetsPad5Rows = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    
    // Provided:
    // Keyboard size
    let idiom: LayoutIdiom
    let isPortrait: Bool
    let keyboardSize: CGSize
    let keyboardViewInsets: UIEdgeInsets
    
    // General
    let keyHeight: CGFloat
    let autoCompleteBarHeight: CGFloat
    let keyViewInsets: UIEdgeInsets
    
    // Idiom specific constants
    let phoneLayoutConstants: PhoneLayoutConstants?
    let padShortLayoutConstants: PadShortLayoutConstants?
    let padFull4RowsLayoutConstants: PadFull4RowsLayoutConstants?
    let padFull5RowsLayoutConstants: PadFull5RowsLayoutConstants?

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
                  keyHeight: CGFloat,
                  autoCompleteBarHeight: CGFloat,
                  keyViewInsets: UIEdgeInsets,
                  keyboardViewLeftRightInset: CGFloat,
                  keyboardViewBottomInset: CGFloat,
                  keyboardSuperviewWidth: CGFloat,
                  keyRowGapY: CGFloat? = nil,
                  phoneLayoutConstants: PhoneLayoutConstants? = nil,
                  padShortLayoutConstants: PadShortLayoutConstants? = nil,
                  padFull4RowsLayoutConstants: PadFull4RowsLayoutConstants? = nil,
                  padFull5RowsLayoutConstants: PadFull5RowsLayoutConstants? = nil) {
        self.idiom = idiom
        self.isPortrait = isPortrait
        self.keyboardSize = keyboardSize
        self.buttonGapX = buttonGapX
        self.keyboardViewInsets = UIEdgeInsets(top: Self.keyboardViewTopInset, left: keyboardViewLeftRightInset, bottom: keyboardViewBottomInset, right: keyboardViewLeftRightInset)
        self.keyHeight = keyHeight
        self.autoCompleteBarHeight = autoCompleteBarHeight
        self.keyViewInsets = keyViewInsets
        let keyboardViewHeight = keyboardSize.height - autoCompleteBarHeight - Self.keyboardViewTopInset - keyboardViewBottomInset
        self.keyboardViewHeight = keyboardViewHeight
        self.keyRowGapY = keyRowGapY ?? (keyboardViewHeight - 4 * keyHeight) / 3
        
        keyboardSuperviewSize = CGSize(width: keyboardSuperviewWidth, height: keyboardSize.height)
        
        let width = (keyboardSize.width - 2 * keyboardViewLeftRightInset - 4 * buttonGapX) / 5
        let height = ((keyboardSize.height - Self.keyboardViewTopInset - keyboardViewBottomInset - autoCompleteBarHeight) - 3 * buttonGapX) / 4
        keypadButtonUnitSize = CGSize(width: width, height: height)
        
        self.phoneLayoutConstants = phoneLayoutConstants
        self.padShortLayoutConstants = padShortLayoutConstants
        self.padFull4RowsLayoutConstants = padFull4RowsLayoutConstants
        self.padFull5RowsLayoutConstants = padFull5RowsLayoutConstants
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
        let letterKeyWidth = (keyboardSize.width - 2 * keyboardViewLeftRightInset - 9 * buttonGapX) / 10
        return LayoutConstants(
            idiom: .phone,
            isPortrait: isPortrait,
            keyboardSize: keyboardSize,
            buttonGapX: buttonGapX,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            keyViewInsets: Self.contentEdgeInsetsPhone,
            keyboardViewLeftRightInset: keyboardViewLeftRightInset,
            keyboardViewBottomInset: 4,
            keyboardSuperviewWidth: keyboardSuperviewWidth,
            phoneLayoutConstants: PhoneLayoutConstants(letterKeyWidth: letterKeyWidth, systemKeyWidth: systemKeyWidth, shiftKeyWidth: shiftKeyWidth))
    }
    
    internal static func makeiPadShortLayout(isPortrait: Bool,
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
            idiom: .pad(.padShort),
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + rowGapY * 3 + autoCompleteBarHeight + Self.keyboardViewTopInset + keyboardViewBottomInset),
            buttonGapX: buttonGapX,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            keyViewInsets: Self.contentEdgeInsetsPadShortAndFull,
            keyboardViewLeftRightInset: keyboardViewLeftRightInset,
            keyboardViewBottomInset: keyboardViewBottomInset,
            keyboardSuperviewWidth: keyboardSuperviewWidth,
            padShortLayoutConstants: PadShortLayoutConstants(rightShiftKeyWidth: rightShiftKeyWidth, returnKeyWidth: returnKeyWidth))
    }
    
    internal static func makeiPadFull4RowsLayout(isPortrait: Bool,
                                            keyboardWidth: CGFloat,
                                            keyboardViewLeftRightInset: CGFloat,
                                            keyboardViewBottomInset: CGFloat,
                                            keyboardSuperviewWidth: CGFloat,
                                            buttonGapX: CGFloat,
                                            rowGapY: CGFloat,
                                            autoCompleteBarHeight: CGFloat,
                                            keyHeight: CGFloat,
                                            tabDeleteKeyWidth: CGFloat,
                                            capLockKeyWidth: CGFloat,
                                            leftShiftKeyWidth: CGFloat,
                                            smallSystemKeyWidth: CGFloat,
                                            returnKeyWidth: CGFloat,
                                            rightShiftKeyWidth: CGFloat,
                                            largeSystemKeyWidth: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            idiom: .pad(.padFull4Rows),
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + rowGapY * 3 + autoCompleteBarHeight + Self.keyboardViewTopInset + keyboardViewBottomInset),
            buttonGapX: buttonGapX,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            keyViewInsets: Self.contentEdgeInsetsPadShortAndFull,
            keyboardViewLeftRightInset: keyboardViewLeftRightInset,
            keyboardViewBottomInset: keyboardViewBottomInset,
            keyboardSuperviewWidth: keyboardSuperviewWidth,
            padFull4RowsLayoutConstants: PadFull4RowsLayoutConstants(
                tabDeleteKeyWidth: tabDeleteKeyWidth,
                capLockKeyWidth: capLockKeyWidth, leftShiftKeyWidth: leftShiftKeyWidth, smallSystemKeyWidth: smallSystemKeyWidth,
                returnKeyWidth: returnKeyWidth, rightShiftKeyWidth: rightShiftKeyWidth, largeSystemKeyWidth: largeSystemKeyWidth))
    }
    
    internal static func makeiPadFull5RowsLayout(isPortrait: Bool,
                                                 keyboardWidth: CGFloat,
                                                 keyboardViewLeftRightInset: CGFloat,
                                                 keyboardViewBottomInset: CGFloat,
                                                 keyboardSuperviewWidth: CGFloat,
                                                 buttonGapX: CGFloat,
                                                 rowGapY: CGFloat,
                                                 autoCompleteBarHeight: CGFloat,
                                                 keyHeight: CGFloat,
                                                 topRowKeyHeight: CGFloat,
                                                 tabKeyWidth: CGFloat,
                                                 capLockKeyWidth: CGFloat,
                                                 leftShiftKeyWidth: CGFloat,
                                                 smallSystemKeyWidth: CGFloat,
                                                 deleteKeyWidth: CGFloat,
                                                 returnKeyWidth: CGFloat,
                                                 rightShiftKeyWidth: CGFloat,
                                                 largeSystemKeyWidth: CGFloat) -> LayoutConstants {
        return LayoutConstants(
            idiom: .pad(.padFull5Rows),
            isPortrait: isPortrait,
            keyboardSize: CGSize(width: keyboardWidth, height: keyHeight * 4 + topRowKeyHeight + rowGapY * 4 + autoCompleteBarHeight + Self.keyboardViewTopInset + keyboardViewBottomInset),
            buttonGapX: buttonGapX,
            keyHeight: keyHeight,
            autoCompleteBarHeight: autoCompleteBarHeight,
            keyViewInsets: Self.contentEdgeInsetsPad5Rows,
            keyboardViewLeftRightInset: keyboardViewLeftRightInset,
            keyboardViewBottomInset: keyboardViewBottomInset,
            keyboardSuperviewWidth: keyboardSuperviewWidth,
            keyRowGapY: rowGapY,
            padFull5RowsLayoutConstants: PadFull5RowsLayoutConstants(
                topRowKeyHeight: topRowKeyHeight,
                tabKeyWidth: tabKeyWidth, capLockKeyWidth: capLockKeyWidth, leftShiftKeyWidth: leftShiftKeyWidth, smallSystemKeyWidth: smallSystemKeyWidth,
                deleteKeyWidth: deleteKeyWidth, returnKeyWidth: returnKeyWidth, rightShiftKeyWidth: rightShiftKeyWidth, largeSystemKeyWidth: largeSystemKeyWidth))
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
    IntDuplet(1024, 1366): LayoutConstants.makeiPadFull5RowsLayout(
        isPortrait: true,
        keyboardWidth: 1024,
        keyboardViewLeftRightInset: 4,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 1024,
        buttonGapX: 7,
        rowGapY: 6,
        autoCompleteBarHeight: 55,
        keyHeight: 62,
        topRowKeyHeight: 47,
        tabKeyWidth: 106,
        capLockKeyWidth: 119,
        leftShiftKeyWidth: 154,
        smallSystemKeyWidth: 94,
        deleteKeyWidth: 106,
        returnKeyWidth: 120,
        rightShiftKeyWidth: 155,
        largeSystemKeyWidth: 143),
    // Landscape:
    IntDuplet(1366, 1024): LayoutConstants.makeiPadFull5RowsLayout(
        isPortrait: false,
        keyboardWidth: 1366,
        keyboardViewLeftRightInset: 4.5,
        keyboardViewBottomInset: 3,
        keyboardSuperviewWidth: 1366,
        buttonGapX: 9,
        rowGapY: 8,
        autoCompleteBarHeight: 55,
        keyHeight: 80,
        topRowKeyHeight: 60,
        tabKeyWidth: 135,
        capLockKeyWidth: 157,
        leftShiftKeyWidth: 204,
        smallSystemKeyWidth: 126,
        deleteKeyWidth: 135,
        returnKeyWidth: 157,
        rightShiftKeyWidth: 204,
        largeSystemKeyWidth: 192),
    
    // iPad 834×1194 iPad Pro 11"
    // Portrait:
    IntDuplet(834, 1194): LayoutConstants.makeiPadFull4RowsLayout(
        isPortrait: true,
        keyboardWidth: 834,
        keyboardViewLeftRightInset: 10,
        keyboardViewBottomInset: 8,
        keyboardSuperviewWidth: 834,
        buttonGapX: 10,
        rowGapY: 8,
        autoCompleteBarHeight: 55,
        keyHeight: 56,
        tabDeleteKeyWidth: 59.5,
        capLockKeyWidth: 86,
        leftShiftKeyWidth: 112.5,
        smallSystemKeyWidth: 59.5,
        returnKeyWidth: 106,
        rightShiftKeyWidth: 89.5,
        largeSystemKeyWidth: 94),
    // Landscape:
    IntDuplet(1194, 834): LayoutConstants.makeiPadFull4RowsLayout(
        isPortrait: false,
        keyboardWidth: 1194,
        keyboardViewLeftRightInset: 14,
        keyboardViewBottomInset: 10,
        keyboardSuperviewWidth: 1180,
        buttonGapX: 14,
        rowGapY: 11,
        autoCompleteBarHeight: 55,
        keyHeight: 75,
        tabDeleteKeyWidth: 103,
        capLockKeyWidth: 136,
        leftShiftKeyWidth: 179,
        smallSystemKeyWidth: 82.5,
        returnKeyWidth: 164.5,
        rightShiftKeyWidth: 121.5,
        largeSystemKeyWidth: 121.5),
    
    // iPad 820×1180 iPad Air (gen 4) 10.9"
    // Portrait:
    IntDuplet(820, 1180): LayoutConstants.makeiPadFull4RowsLayout(
        isPortrait: true,
        keyboardWidth: 820,
        keyboardViewLeftRightInset: 10,
        keyboardViewBottomInset: 8,
        keyboardSuperviewWidth: 820,
        buttonGapX: 10,
        rowGapY: 8,
        autoCompleteBarHeight: 55,
        keyHeight: 55,
        tabDeleteKeyWidth: 58,
        capLockKeyWidth: 85,
        leftShiftKeyWidth: 110.5,
        smallSystemKeyWidth: 58.5,
        returnKeyWidth: 102,
        rightShiftKeyWidth: 86,
        largeSystemKeyWidth: 94),
    // Landscape:
    IntDuplet(1180, 820): LayoutConstants.makeiPadFull4RowsLayout(
        isPortrait: false,
        keyboardWidth: 1180,
        keyboardViewLeftRightInset: 14,
        keyboardViewBottomInset: 10,
        keyboardSuperviewWidth: 1180,
        buttonGapX: 14,
        rowGapY: 11,
        autoCompleteBarHeight: 55,
        keyHeight: 73,
        tabDeleteKeyWidth: 101,
        capLockKeyWidth: 134,
        leftShiftKeyWidth: 176,
        smallSystemKeyWidth: 81.5,
        returnKeyWidth: 161,
        rightShiftKeyWidth: 120,
        largeSystemKeyWidth: 121.5),
    
    // iPad 810×1080 iPad (gen 8/7) 10.2"
    // Portrait:
    IntDuplet(810, 1080): LayoutConstants.makeiPadShortLayout(
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
    IntDuplet(1080, 810): LayoutConstants.makeiPadShortLayout(
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
    IntDuplet(834, 1112): LayoutConstants.makeiPadShortLayout(
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
    IntDuplet(1112, 834): LayoutConstants.makeiPadShortLayout(
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
    IntDuplet(768, 1024): LayoutConstants.makeiPadShortLayout(
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
    IntDuplet(1024, 768): LayoutConstants.makeiPadShortLayout(
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
