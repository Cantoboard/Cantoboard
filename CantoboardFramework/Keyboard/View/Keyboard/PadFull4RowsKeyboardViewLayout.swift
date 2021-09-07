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
        [["\t", "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", .backspace]],
        [[.capsLock, "a", "s", "d", "f", "g", "h", "j", "k", "l", .returnKey(.default)]],
        [[.shift(.lowercased), "z", "x", "c", "v", "b", "n", "m", ",", ".", .shift(.lowercased)]],
        [[.nextKeyboard, .keyboardType(.numeric)], [.contextualSymbols(.english), .space(.space)], [.keyboardType(.numeric), .dismissKeyboard]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", .backspace]],
        [["@", "#", "$", "&", "*", "(", ")", "’", "”", .returnKey(.default)]],
        [[.keyboardType(.symbolic), "%", "-", "+", "=", "/", ";", ":", ",", ".", .keyboardType(.symbolic)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], [.contextualSymbols(.english), .keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", .backspace]],
        [["@", "#", "$", "&", "*", "(", ")", "’", "”", .returnKey(.default)]],
        [[.keyboardType(.symbolic), "%", "-", "+", "=", "/", ";", ":", ",", ".", .keyboardType(.symbolic)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], [.contextualSymbols(.english), .keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsHalf: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", .backspace]],
        [["€", "£", "¥", "_", "^", "[", "]", "{", "}", .returnKey(.default)]],
        [[.keyboardType(.numeric), "§", "|", "~", "…", "\\", "<", ">", "!", "?", .keyboardType(.numeric)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], [.contextualSymbols(.english), .keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsFull: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", .backspace]],
        [["€", "£", "¥", "_", "^", "[", "]", "{", "}", .returnKey(.default)]],
        [[.keyboardType(.numeric), "§", "|", "~", "…", "\\", "<", ">", "!", "?", .keyboardType(.numeric)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], [.contextualSymbols(.english), .keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect] {
        let directionalLayoutMargins = keyRowView.directionalLayoutMargins
        let bounds = keyRowView.bounds
        
        let availableWidth = bounds.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        
        let allKeys = leftKeys + middleKeys + rightKeys
        
        var numFlexibleWidthKeys: Int = 0
        var keyWidths = Dictionary<KeyView, CGFloat>()
        
        let takenWidth = getPadFullFixedKeyWidth(keys: allKeys, layoutConstants: layoutConstants, numFlexibleWidthKeys: &numFlexibleWidthKeys, keyWidths: &keyWidths)
        
        let totalGapWidth = CGFloat(allKeys.count - 1) * layoutConstants.buttonGapX
        let flexibleKeyWidth = (availableWidth - takenWidth - totalGapWidth) / CGFloat(numFlexibleWidthKeys)
        
        var allFrames: [CGRect]
        var x = directionalLayoutMargins.leading
        
        allFrames = layoutPadFullKeys(keys: allKeys, keyWidths: keyWidths, flexibleKeyWidth: flexibleKeyWidth, buttonGapX: layoutConstants.buttonGapX, keyHeight: layoutConstants.keyHeight, marginTop: directionalLayoutMargins.top, x: &x)
        
        return allFrames
    }
    
    private static func getPadFullFixedKeyWidth(keys: [KeyView], layoutConstants: LayoutConstants, numFlexibleWidthKeys: inout Int, keyWidths: inout Dictionary<KeyView, CGFloat>) -> CGFloat {
        let padFullLayoutConstants = layoutConstants.padFullLayoutConstants!
        
        let totalFixedKeyWidth = keys.enumerated().reduce(CGFloat(0)) {sum, indexAndKey in
            let index = indexAndKey.offset
            let key = indexAndKey.element
            
            var width: CGFloat
            switch key.keyCap {
            case "\t", .backspace: width = padFullLayoutConstants.tabDeleteKeyWidth
            case .capsLock: width = padFullLayoutConstants.capLockKeyWidth
            case .shift:
                if index == 0 {
                    width = padFullLayoutConstants.leftShiftKeyWidth
                } else {
                    width = padFullLayoutConstants.rightShiftKeyWidth
                }
            case .returnKey: width = padFullLayoutConstants.returnKeyWidth
            case .nextKeyboard, .contextualSymbols,
                 .keyboardType where index <= 2:
                width = padFullLayoutConstants.leftSystemKeyWidth
            case .keyboardType, .dismissKeyboard:
                width = padFullLayoutConstants.rightSystemKeyWidth
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
    
    private static func layoutPadFullKeys(keys: [KeyView], keyWidths: Dictionary<KeyView, CGFloat>, flexibleKeyWidth: CGFloat, buttonGapX: CGFloat, keyHeight: CGFloat, marginTop: CGFloat, x: inout CGFloat) -> [CGRect] {
        return keys.map { key in
            let keyWidth = keyWidths[key, default: flexibleKeyWidth]
            let rect = CGRect(x: x, y: marginTop, width: keyWidth, height: keyHeight)
            x += rect.width + buttonGapX
            
            return rect
        }
    }
}
