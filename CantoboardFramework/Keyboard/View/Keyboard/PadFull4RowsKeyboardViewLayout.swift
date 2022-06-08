//
//  PadFull4RowsKeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/6/21.
//

import Foundation

import Foundation
import UIKit

class PadFull4RowsKeyboardViewLayout : KeyboardViewLayout {
    static let numOfRows = 4
    
    static let letters: [[[KeyCap]]] = [
        [["\t"], ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], [.backspace]],
        [[.toggleInputMode(.english, nil)], ["a", "s", "d", "f", "g", "h", "j", "k", "l"], [.returnKey(.default)]],
        [[.shift(.lowercased)], ["z", "x", "c", "v", "b", "n", "m", .contextual(","), .contextual(".")], [.shift(.lowercased)]],
        [[.nextKeyboard, .keyboardType(.numSymbolic), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.numSymbolic), .dismissKeyboard]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [["\t"], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[.placeholder(.toggleInputMode(.english, nil))], ["@", "#", .currency, "/", "(", ")", "「", "」", .singleQuote], [.returnKey(.default)]],
        [[.keyboardType(.symbolic)], ["%", "-", "~", "…", "､", ";", ":", ",", "."], [.keyboardType(.symbolic)]],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [["\t"], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[.placeholder(.toggleInputMode(.english, nil))], ["@", "#", .currency, "／", "（", "）", "「", "」", .singleQuote], [.returnKey(.default)]],
        [[.keyboardType(.symbolic)], ["%", "—", "～", "⋯", "、", "；", "：", "，", "。"], [.keyboardType(.symbolic)]],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsHalf: [[[KeyCap]]] = [
        [["\t"], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[.placeholder(.toggleInputMode(.english, nil))], ["^", "_", "|", "\\", "[", "]", "{", "}", .doubleQuote], [.returnKey(.default)]],
        [[.keyboardType(.numeric)], ["*", "&", "+", "=", "•", "<", ">", "!", "?"], [.keyboardType(.numeric)]],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsFull: [[[KeyCap]]] = [
        [["\t"], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[.placeholder(.toggleInputMode(.english, nil))], ["^", "_", "｜", "＼", "［", "］", "｛", "｝", .doubleQuote], [.returnKey(.default)]],
        [[.keyboardType(.numeric)], ["*", "&", "+", "=", "·", "《", "》", "！", "？"], [.keyboardType(.numeric)]],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect] {
        let directionalLayoutMargins = keyRowView.directionalLayoutMargins
        let bounds = keyRowView.bounds
        
        let availableWidth = bounds.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        
        let allKeys = leftKeys + middleKeys + rightKeys
        
        var numFlexibleWidthKeys: Int = 0
        var keyWidths = Dictionary<KeyView, CGFloat>()
        
        var takenWidth: CGFloat = 0
        takenWidth += getFixedKeyWidth(keyRowView: keyRowView, keys: leftKeys, groupLayoutDirection: .left, layoutConstants: layoutConstants, numFlexibleWidthKeys: &numFlexibleWidthKeys, keyWidths: &keyWidths)
        takenWidth += getFixedKeyWidth(keyRowView: keyRowView, keys: middleKeys, groupLayoutDirection: .middle, layoutConstants: layoutConstants, numFlexibleWidthKeys: &numFlexibleWidthKeys, keyWidths: &keyWidths)
        takenWidth += getFixedKeyWidth(keyRowView: keyRowView, keys: rightKeys, groupLayoutDirection: .right, layoutConstants: layoutConstants, numFlexibleWidthKeys: &numFlexibleWidthKeys, keyWidths: &keyWidths)

        let totalGapWidth = CGFloat(allKeys.count - 1) * layoutConstants.buttonGapX
        let flexibleKeyWidth = (availableWidth - takenWidth - totalGapWidth) / CGFloat(numFlexibleWidthKeys)
        
        var allFrames: [CGRect]
        var x = directionalLayoutMargins.leading
        
        allFrames = layoutKeys(keys: allKeys, keyWidths: keyWidths, flexibleKeyWidth: flexibleKeyWidth, buttonGapX: layoutConstants.buttonGapX, keyHeight: layoutConstants.keyHeight, marginTop: directionalLayoutMargins.top, x: &x)
        
        return allFrames
    }
    
    private static func layoutKeys(keys: [KeyView], keyWidths: Dictionary<KeyView, CGFloat>, flexibleKeyWidth: CGFloat, buttonGapX: CGFloat, keyHeight: CGFloat, marginTop: CGFloat, x: inout CGFloat) -> [CGRect] {
        return keys.map { key in
            let keyWidth = keyWidths[key, default: flexibleKeyWidth]
            let rect = CGRect(x: x, y: marginTop, width: keyWidth, height: keyHeight)
            x += rect.width + buttonGapX
            
            return rect
        }
    }
    
    private static func getFixedKeyWidth(keyRowView: KeyRowView, keys: [KeyView], groupLayoutDirection: GroupLayoutDirection, layoutConstants: LayoutConstants, numFlexibleWidthKeys: inout Int, keyWidths: inout Dictionary<KeyView, CGFloat>) -> CGFloat {
        let padFull4RowsLayoutConstants = layoutConstants.asPadFull4RowsLayoutConstants!
        
        let totalFixedKeyWidth = keys.reduce(CGFloat(0)) { sum, key in
            let width: CGFloat
            
            switch key.keyCap.unescaped {
            case "\t", .backspace: width = padFull4RowsLayoutConstants.tabDeleteKeyWidth
            case .toggleInputMode: width = padFull4RowsLayoutConstants.capLockKeyWidth
            case .shift, .keyboardType(.numeric), .keyboardType(.symbolic):
                if groupLayoutDirection == .left {
                    width = padFull4RowsLayoutConstants.leftShiftKeyWidth
                } else {
                    width = padFull4RowsLayoutConstants.rightShiftKeyWidth
                }
            case .returnKey: width = padFull4RowsLayoutConstants.returnKeyWidth
            default:
                if keyRowView.rowId == 3 && groupLayoutDirection == .left {
                    let groupWidth = padFull4RowsLayoutConstants.smallSystemKeyWidth * 3 + 2 * layoutConstants.buttonGapX
                    let buttonCount = CGFloat(keys.count)
                    width = (groupWidth - (buttonCount - 1) * layoutConstants.buttonGapX) / buttonCount
                } else if keyRowView.rowId == 3 && groupLayoutDirection == .right {
                    let groupWidth = padFull4RowsLayoutConstants.largeSystemKeyWidth * 2 + layoutConstants.buttonGapX
                    let buttonCount = CGFloat(keys.count)
                    width = (groupWidth - (buttonCount - 1) * layoutConstants.buttonGapX) / buttonCount
                } else {
                    width = 0
                    numFlexibleWidthKeys += 1
                }
            }
            
            if width > 0 {
                keyWidths[key] = width
            }
            
            return sum + width
        }
        
        return totalFixedKeyWidth
    }
    
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap? {
        return CommonContextualKeys.getContextualKeys(key: key, keyboardState: keyboardState)
    }
    
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat {
        return layoutConstants.keyHeight
    }
    
    static func getSwipeDownKeyCap(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap? {
        return CommonSwipeDownKeys.getSwipeDownKeyCapForPadShortOrFull4Rows(keyCap: keyCap, keyboardState: keyboardState)
    }
    
    static func isSwipeDownKeyShiftMorphing(keyCap: KeyCap) -> Bool {
        return keyCap == "," || keyCap == "." || keyCap == "，" || keyCap == "。"
    }
}
