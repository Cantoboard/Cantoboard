//
//  PhoneKeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/6/21.
//

import Foundation
import UIKit

class PhoneKeyboardViewLayout : KeyboardViewLayout {
    static let numOfRows = 4
    
    static let letters: [[[KeyCap]]] = [
        [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]],
        [["a", "s", "d", "f", "g", "h", "j", "k", "l"]],
        [[.shift(.lowercased)], ["z", "x", "c", "v", "b", "n", "m"], [.backspace]],
        [[.keyboardType(.numeric), .nextKeyboard, .toggleInputMode(.english, nil, true)], [.space(.space)], [.contextual(.symbol), .returnKey(.default)]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]],
        [["-", "/", ":", ";", "(", ")", .currency, .doubleQuote, "「", "」"]],
        [[.keyboardType(.symbolic)], [".", ",", "､", "^_^", "?", "!", .singleQuote], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], ["@", .returnKey(.default)]]
    ]
    
    static let symbolsHalf: [[[KeyCap]]] = [
        [["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]],
        [["_", "\\", "|", "~", "<", ">", "«", "»", "&", "•"]],
        [[.keyboardType(.numeric)], [".", ",", "､", "^_^", "?", "!", .singleQuote], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], ["…", .returnKey(.default)]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]],
        [["—", "／", "：", "；", "（", "）", .currency, .doubleQuote, "「", "」"]],
        [[.keyboardType(.symbolic)], ["。", "，", "、", "^_^", "？", "！", .singleQuote], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], ["@", .returnKey(.default)]]
    ]
    
    static let symbolsFull: [[[KeyCap]]] = [
        [["［", "］", "｛", "｝", "#", "%", "^", "*", "+", "="]],
        [["_", "＼", "｜", "～", "〈", "〉", "《", "》", "&", "·"]],
        [[.keyboardType(.numeric)], ["。", "，", "、", "^_^", "？", "！", .singleQuote], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], ["⋯", .returnKey(.default)]]
    ]
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect] {
        // First, put the keys to where they should be.
        let leftKeyFrames = layoutKeyGroup(keyRowView: keyRowView, leftKeys, direction: .left, layoutConstants: layoutConstants)
        let middleKeyFrames = layoutKeyGroup(keyRowView: keyRowView, middleKeys, direction: .middle, layoutConstants: layoutConstants)
        let rightKeyFrames = layoutKeyGroup(keyRowView: keyRowView, rightKeys, direction: .right, layoutConstants: layoutConstants)
        
        var allFrames = leftKeyFrames + middleKeyFrames + rightKeyFrames
        
        // Special case, widen the space key to fill the empty space.
        if keyRowView.rowId == 3 && middleKeys.count == 1, case .space = middleKeys.first!.keyCap {
            let thisKeyFrame = allFrames[leftKeyFrames.count]
            let spaceStartX = allFrames[leftKeyFrames.count - 1].maxX + layoutConstants.buttonGapX
            let spaceEndX = allFrames[leftKeyFrames.count + middleKeyFrames.count].minX - layoutConstants.buttonGapX
            allFrames[leftKeyFrames.count] = CGRect(x: spaceStartX, y: thisKeyFrame.minY, width: spaceEndX - spaceStartX, height: thisKeyFrame.maxY - thisKeyFrame.minY)
        }
        
        return allFrames
    }
    
    private static func layoutKeyGroup(keyRowView: KeyRowView, _ keys: [KeyView], direction: GroupLayoutDirection, layoutConstants: LayoutConstants) -> [CGRect] {
        let directionalLayoutMargins = keyRowView.directionalLayoutMargins
        let bounds = keyRowView.bounds
        
        var x: CGFloat
        switch direction {
        case .left:
            x = directionalLayoutMargins.leading
        case .middle:
            let middleKeysCount = CGFloat(keys.count)
            let middleKeysWidth = keys.reduce(0, { $0 + getKeyWidth($1, layoutConstants) }) + (middleKeysCount - 1) * layoutConstants.buttonGapX
            x = (bounds.width - middleKeysWidth) / 2
        case .right:
            let rightKeysCount = CGFloat(keys.count)
            let rightKeysWidth = keys.reduce(0, { $0 + getKeyWidth($1, layoutConstants) }) + (rightKeysCount - 1) * layoutConstants.buttonGapX
            x = bounds.maxX - directionalLayoutMargins.trailing - rightKeysWidth
        }
        
        let frames: [CGRect] = keys.map { key in
            let keyWidth: CGFloat
            if keyRowView.rowId == 3 && direction == .left && keys.count > 2 {
                keyWidth = (layoutConstants.asPhoneLayoutConstants!.letterKeyWidth + layoutConstants.asPhoneLayoutConstants!.systemKeyWidth) / 2
            } else {
                keyWidth = getKeyWidth(key, layoutConstants)
            }
            let rect = CGRect(x: x, y: directionalLayoutMargins.top, width: keyWidth, height: layoutConstants.keyHeight)
            x += keyWidth + layoutConstants.buttonGapX
            
            return rect
        }
        return frames
    }
    
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap? {
        return CommonContextualKeys.getContextualKeys(key: key, keyboardState: keyboardState)
    }
    
    private static func getKeyWidth(_ key: KeyView, _ layoutConstants: LayoutConstants) -> CGFloat {
        switch key.keyCap {
        case .shift, .toggleInputMode, .keyboardType(.symbolic), .backspace:
            return layoutConstants.asPhoneLayoutConstants!.shiftKeyWidth
        case .returnKey:
            return 1.5 * layoutConstants.asPhoneLayoutConstants!.systemKeyWidth
        case .character, .cangjie, .rime, .currency, .singleQuote, .doubleQuote:
            return layoutConstants.asPhoneLayoutConstants!.letterKeyWidth
        default:
            return layoutConstants.asPhoneLayoutConstants!.systemKeyWidth
        }
    }
    
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat {
        return layoutConstants.keyHeight
    }
    
    static func getSwipeDownKeyCap(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap? {
        return nil
    }
    
    static func isSwipeDownKeyShiftMorphing(keyCap: KeyCap) -> Bool {
        return false
    }
}
