//
//  PadFull4RowsKeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/6/21.
//

import Foundation

import Foundation
import UIKit

class PadFull5RowsKeyboardViewLayout : KeyboardViewLayout {
    static let numOfRows = 5
    
    static let letters: [[[KeyCap]]] = [
        [[], ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="], [.backspace]],
        [["\t"], ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\"], []],
        [[.capsLock], ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "’"], [.returnKey(.default)]],
        [[.shift(.lowercased)], ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"], [.shift(.lowercased)]],
        [[.nextKeyboard, .keyboardType(.numeric)], [.contextualSymbols(.english), .space(.space)], [.keyboardType(.numeric), .dismissKeyboard]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [[], ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "<", ">"], [.backspace]],
        [["\t"], ["[", "]", "{", "}", "#", "%", "^", "*", "+", "=", "\\", "|", "_"], []],
        [[.placeholder(.capsLock)], ["-", "/", ":", ";", "(", ")", .currency, "&", "@", "’", "¥"], [.returnKey(.default)]],
        [[.placeholder(.shift(.lowercased))], ["^_^", "…", ".", ",", "、", "?", "!", "~", "”", "”", "€", "£"], []],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .contextualSymbols(.english)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [[], ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "<", ">"], [.backspace]],
        [["\t"], ["［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝", "＼", "｜", "＿"], []],
        [[.placeholder(.capsLock)], ["－", "／", "：", "；", "（", "）", .currency, "＆", "＠", "’", "¥"], [.returnKey(.default)]],
        [[.placeholder(.shift(.lowercased))], ["^_^", "⋯", "。", "，", "、", "？", "！", "～", "＂", "＇", "「", "」"], []],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .contextualSymbols(.english)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsHalf: [[[KeyCap]]] = numbersHalf
    
    static let symbolsFull: [[[KeyCap]]] = numbersFull
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect] {
        let directionalLayoutMargins = keyRowView.directionalLayoutMargins
        let bounds = keyRowView.bounds
        
        let availableWidth = bounds.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        
        let allKeys = leftKeys + middleKeys + rightKeys
        
        var numFlexibleWidthKeys: Int = 0
        var keyWidths = Dictionary<KeyView, CGFloat>()
        
        let inputKeyWidth = (availableWidth - layoutConstants.padFull5RowsLayoutConstants!.deleteKeyWidth - 13 * layoutConstants.buttonGapX) / CGFloat(13)
        let takenWidth = getFixedKeyWidth(keys: allKeys, inputKeyWidth: inputKeyWidth, layoutConstants: layoutConstants, numFlexibleWidthKeys: &numFlexibleWidthKeys, keyWidths: &keyWidths)
        
        let totalGapWidth = CGFloat(allKeys.count - 1) * layoutConstants.buttonGapX
        let flexibleKeyWidth = (availableWidth - takenWidth - totalGapWidth) / CGFloat(numFlexibleWidthKeys)
        
        let keyHeight = getKeyHeight(atRow: keyRowView.rowId, layoutConstants: layoutConstants)
        
        var allFrames: [CGRect]
        var x = directionalLayoutMargins.leading
        
        allFrames = layoutKeys(keys: allKeys, keyWidths: keyWidths, flexibleKeyWidth: flexibleKeyWidth, buttonGapX: layoutConstants.buttonGapX, keyHeight: keyHeight, marginTop: directionalLayoutMargins.top, x: &x)
        
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
    
    private static func getFixedKeyWidth(keys: [KeyView], inputKeyWidth: CGFloat, layoutConstants: LayoutConstants, numFlexibleWidthKeys: inout Int, keyWidths: inout Dictionary<KeyView, CGFloat>) -> CGFloat {
        let padFull5RowsLayoutConstants = layoutConstants.padFull5RowsLayoutConstants!
        
        let totalFixedKeyWidth = keys.enumerated().reduce(CGFloat(0)) {sum, indexAndKey in
            let index = indexAndKey.offset
            let key = indexAndKey.element
            
            let keyCap: KeyCap
            if case let .placeholder(keyCapSizer) = key.keyCap {
                keyCap = keyCapSizer
            } else {
                keyCap = key.keyCap
            }
            
            var width: CGFloat
            switch keyCap {
            case "\t": width = padFull5RowsLayoutConstants.tabKeyWidth
            case .capsLock: width = padFull5RowsLayoutConstants.capLockKeyWidth
            case .shift:
                if index == 0 {
                    width = padFull5RowsLayoutConstants.leftShiftKeyWidth
                } else {
                    width = padFull5RowsLayoutConstants.rightShiftKeyWidth
                }
                
            case .backspace: width = padFull5RowsLayoutConstants.deleteKeyWidth
            case .returnKey: width = padFull5RowsLayoutConstants.returnKeyWidth
            case .nextKeyboard, .contextualSymbols,
                 .keyboardType where index <= 2:
                width = padFull5RowsLayoutConstants.leftSystemKeyWidth
            case .keyboardType, .dismissKeyboard:
                width = padFull5RowsLayoutConstants.rightSystemKeyWidth
            case .character, .cangjie, .currency: width = inputKeyWidth
            default:
                width = 0
                numFlexibleWidthKeys += 1
            }
            
            if width > 0 {
                keyWidths[key] = width
            }
            
            return sum + width
        }
        
        return totalFixedKeyWidth
    }
    
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat {
        return atRow == 0 ? layoutConstants.padFull5RowsLayoutConstants!.topRowKeyHeight : layoutConstants.keyHeight
    }
}
