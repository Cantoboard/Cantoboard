//
//  PadFull5RowsKeyboardViewLayout.swift
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
        [[], [.contextual("•"), "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="], [.backspace]],
        [["\t"], ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", .contextual("["), .contextual("]"), .contextual("\\")], []],
        [[.toggleInputMode(.english, nil)], ["a", "s", "d", "f", "g", "h", "j", "k", "l", .contextual(";"), .singleQuote], [.returnKey(.default)]],
        [[.shift(.lowercased)], ["z", "x", "c", "v", "b", "n", "m", .contextual(","), .contextual("."), .contextual("/")], [.shift(.lowercased)]],
        [[.nextKeyboard, .keyboardType(.numSymbolic), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.numSymbolic), .dismissKeyboard]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [[], ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "<", ">"], [.backspace]],
        [["\t"], ["[", "]", "{", "}", "#", "%", "^", "*", "+", "=", "\\", "|", "_"], []],
        [[.placeholder(.toggleInputMode(.english, nil))], ["-", "/", ":", ";", "(", ")", .currency, "&", "@", .singleQuote, .doubleQuote], [.returnKey(.default)]],
        [[.placeholder(.shift(.lowercased))], ["^_^", "…", ".", ",", "､", "?", "!", "~", "「", "」"], [.placeholder(.shift(.lowercased))]],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [[], ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "<", ">"], [.backspace]],
        [["\t"], ["［", "］", "｛", "｝", "#", "%", "^", "*", "+", "=", "＼", "｜", "_"], []],
        [[.placeholder(.toggleInputMode(.english, nil))], ["—", "／", "：", "；", "（", "）", .currency, "&", "@", .singleQuote, .doubleQuote], [.returnKey(.default)]],
        [[.placeholder(.shift(.lowercased))], ["^_^", "⋯", "。", "，", "、", "？", "！", "～", "「", "」"], [.placeholder(.shift(.lowercased))]],
        [[.nextKeyboard, .keyboardType(.alphabetic(.lowercased)), .keyboardType(.emojis)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
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
        
        let inputKeyWidth = (availableWidth - layoutConstants.asPadFull5RowsLayoutConstants!.deleteKeyWidth - 13 * layoutConstants.buttonGapX) / CGFloat(13)
        let takenWidth = getFixedKeyWidth(keyRowView: keyRowView, keys: allKeys, inputKeyWidth: inputKeyWidth, layoutConstants: layoutConstants, numFlexibleWidthKeys: &numFlexibleWidthKeys, keyWidths: &keyWidths)
        
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
    
    private static func getFixedKeyWidth(keyRowView: KeyRowView, keys: [KeyView], inputKeyWidth: CGFloat, layoutConstants: LayoutConstants, numFlexibleWidthKeys: inout Int, keyWidths: inout Dictionary<KeyView, CGFloat>) -> CGFloat {
        let padFull5RowsLayoutConstants = layoutConstants.asPadFull5RowsLayoutConstants!
        
        let totalFixedKeyWidth = keys.enumerated().reduce(CGFloat(0)) {sum, indexAndKey in
            let index = indexAndKey.offset
            let key = indexAndKey.element
            
            let isMiddleSystemKeyGroup = index == keyRowView.leftKeys.count
            if keyRowView.rowId == 4 && !isMiddleSystemKeyGroup {
                let isLeftSystemKeyGroup = index < keyRowView.leftKeys.count
                let leftSystemKeyGroupWidth = padFull5RowsLayoutConstants.smallSystemKeyWidth * 3 + 2 * layoutConstants.buttonGapX
                let rightSystemKeyGroupWidth = padFull5RowsLayoutConstants.largeSystemKeyWidth * 2 + layoutConstants.buttonGapX
                let systemKeyGroupWidth = isLeftSystemKeyGroup ? leftSystemKeyGroupWidth : rightSystemKeyGroupWidth
                let numberOfKeysInGroup = CGFloat(isLeftSystemKeyGroup ? keyRowView.leftKeys.count : keyRowView.rightKeys.count)
                let keyWidth = (systemKeyGroupWidth - (numberOfKeysInGroup - 1) * layoutConstants.buttonGapX) / numberOfKeysInGroup
                
                keyWidths[key] = keyWidth
                return sum + keyWidth
            }
            
            var width: CGFloat
            switch key.keyCap.unescaped {
            case "\t": width = padFull5RowsLayoutConstants.tabKeyWidth
            case .toggleInputMode: width = padFull5RowsLayoutConstants.capLockKeyWidth
            case .shift:
                if index == 0 {
                    width = padFull5RowsLayoutConstants.leftShiftKeyWidth
                } else {
                    width = padFull5RowsLayoutConstants.rightShiftKeyWidth
                }
            case .backspace: width = padFull5RowsLayoutConstants.deleteKeyWidth
            case .returnKey: width = padFull5RowsLayoutConstants.returnKeyWidth
            case .character, .cangjie, .currency, .singleQuote, .doubleQuote: width = inputKeyWidth
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
    
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap? {
        if !keyboardState.keyboardContextualType.halfWidthSymbol {
            switch key {
            case "[": return "「"
            case "]": return "」"
            case "\\": return "、"
            case ";": return "；"
            case "/": return "／"
            case "•": return "·"
            default: ()
            }
        } else if case .character(let c) = key {
            return KeyCap(String(c))
        }
        return CommonContextualKeys.getContextualKeys(key: key, keyboardState: keyboardState)
    }
    
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat {
        return atRow == 0 ? layoutConstants.asPadFull5RowsLayoutConstants!.topRowKeyHeight : layoutConstants.keyHeight
    }
    
    static func getSwipeDownKeyCap(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap? {
        let isInChineseContextualMode = !keyboardState.keyboardContextualType.halfWidthSymbol
        if case .alphabetic = keyboardState.keyboardType {
            switch keyCap {
            case "•": return "~"
            case "·": return "～"
            case "1": return isInChineseContextualMode ? "！" : "!"
            case "2": return "@"
            case "3": return "#"
            case "4": return KeyCap(SessionState.main.currencySymbol)
            case "5": return "%"
            case "6": return isInChineseContextualMode ? "⋯⋯" : "^"
            case "7": return "&"
            case "8": return "*"
            case "9": return isInChineseContextualMode ? "（" : "("
            case "0": return isInChineseContextualMode ? "）" : ")"
            case "-": return isInChineseContextualMode ? "——" : "_"
            case "=": return "+"
            case "[": return "{"
            case "]": return "}"
            case "\\": return "|"
            case ";": return ":"
            case .singleQuote: return .doubleQuote
            case ",": return "<"
            case ".": return ">"
            case "/": return "?"
            case "／": return "？"
            case "，": return "《"
            case "。": return "》"
            case "「": return "『"
            case "」": return "』"
            case "、": return "｜"
            case "；": return "："
            default: ()
            }
        }
        return nil
    }
    
    static func isSwipeDownKeyShiftMorphing(keyCap: KeyCap) -> Bool {
        return true
    }
}
