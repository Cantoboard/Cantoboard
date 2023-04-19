//
//  PadShortKeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/6/21.
//

import Foundation
import UIKit

class PadShortKeyboardViewLayout : KeyboardViewLayout {
    static let numOfRows = 4
    
    static let letters: [[[KeyCap]]] = [
        [[], ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"], [.backspace]],
        [[], ["a", "s", "d", "f", "g", "h", "j", "k", "l"], [.returnKey(.default)]],
        [[.shift(.lowercased)], [ "z", "x", "c", "v", "b", "n", "m", .contextual(","), .contextual(".")], [.shift(.lowercased)]],
        [[.keyboardType(.numSymbolic), .nextKeyboard, .toggleInputMode(.english, nil, true)], [.space(.space)], [.keyboardType(.numSymbolic), .dismissKeyboard]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [[], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[], ["@", "#", .currency, "/", "(", ")", "「", "」", .singleQuote], [.returnKey(.default)]],
        [[.keyboardType(.symbolic)], ["%", "-", "~", "…", "､", ";", ":", ",", "."], [.keyboardType(.symbolic)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard, .toggleInputMode(.english, nil, true)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [[], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[], ["@", "#", .currency, "／", "（", "）", "「", "」", .singleQuote], [.returnKey(.default)]],
        [[.keyboardType(.symbolic)], ["%", "—", "～", "⋯", "、", "；", "：", "，", "。"], [.keyboardType(.symbolic)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard, .toggleInputMode(.english, nil, true)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsHalf: [[[KeyCap]]] = [
        [[], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[], ["^", "_", "|", "\\", "[", "]", "{", "}", .doubleQuote], [.returnKey(.default)]],
        [[.keyboardType(.numeric)], ["*", "&", "+", "=", "•", "<", ">", "!", "?"], [.keyboardType(.numeric)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard, .toggleInputMode(.english, nil, true)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static let symbolsFull: [[[KeyCap]]] = [
        [[], ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"], [.backspace]],
        [[], ["^", "_", "｜", "＼", "［", "］", "｛", "｝", .doubleQuote], [.returnKey(.default)]],
        [[.keyboardType(.numeric)], ["*", "&", "+", "=", "·", "《", "》", "！", "？"], [.keyboardType(.numeric)]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard, .toggleInputMode(.english, nil, true)], [.space(.space)], [.keyboardType(.alphabetic(.lowercased)), .dismissKeyboard]]
    ]
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect] {
        let directionalLayoutMargins = keyRowView.directionalLayoutMargins
        let bounds = keyRowView.bounds
        
        let availableWidth = bounds.width - directionalLayoutMargins.leading - directionalLayoutMargins.trailing
        let rightShiftKeyWidth = layoutConstants.asPadShortLayoutConstants!.rightShiftKeyWidth
        let row3LeftGroupWidth = availableWidth - rightShiftKeyWidth - layoutConstants.buttonGapX
        let keyWidthRow3n4 = (row3LeftGroupWidth - 9 * layoutConstants.buttonGapX) / 10
        
        let allKeys: [KeyView]
        var allFrames: [CGRect]
        
        switch keyRowView.rowId {
        case 0:
            let keyWidth = (availableWidth - 10 * layoutConstants.buttonGapX) / 11
            var x = directionalLayoutMargins.leading
            
            allKeys = leftKeys + middleKeys + rightKeys
            allFrames = layoutKeyViews(keys: allKeys, keyWidth: keyWidth, layoutConstants: layoutConstants, marginTop: directionalLayoutMargins.top, x: &x)
        case 1:
            let leftInset: CGFloat = keyWidthRow3n4 / 2
            let lastKeyWidth = layoutConstants.asPadShortLayoutConstants!.returnKeyWidth
            let keyWidth = (availableWidth - leftInset - lastKeyWidth - 9 * layoutConstants.buttonGapX) / 9
            var x = directionalLayoutMargins.leading + leftInset
            
            allKeys = leftKeys + middleKeys + rightKeys
            allFrames = layoutKeyViews(keys: allKeys, keyWidth: keyWidth, layoutConstants: layoutConstants, marginTop: directionalLayoutMargins.top, x: &x)
            
            overrideLastFrame(frames: &allFrames, width: lastKeyWidth)
        case 2:
            var x = directionalLayoutMargins.leading
            allKeys = leftKeys + middleKeys + rightKeys
            allFrames = layoutKeyViews(keys: allKeys, keyWidth: keyWidthRow3n4, layoutConstants: layoutConstants, marginTop: directionalLayoutMargins.top, x: &x)
            
            overrideLastFrame(frames: &allFrames, width: rightShiftKeyWidth)
        case 3:
            let leftRightGroupWidth: CGFloat = 3 * keyWidthRow3n4 + 2 * layoutConstants.buttonGapX
            var x = directionalLayoutMargins.leading
            
            let leftKeyWidth = (leftRightGroupWidth - CGFloat(leftKeys.count - 1) * layoutConstants.buttonGapX) / CGFloat(leftKeys.count)
            let leftFrames = layoutKeyViews(keys: leftKeys, keyWidth: leftKeyWidth, layoutConstants: layoutConstants, marginTop: directionalLayoutMargins.top, x: &x)
            
            let middleGroupWidth: CGFloat = availableWidth - 2 * leftRightGroupWidth - 2 * layoutConstants.buttonGapX
            let middleKeyWidth = (middleGroupWidth - CGFloat(middleKeys.count - 1) * layoutConstants.buttonGapX) / CGFloat(middleKeys.count)
            let middleFrames = layoutKeyViews(keys: middleKeys, keyWidth: middleKeyWidth, layoutConstants: layoutConstants, marginTop: directionalLayoutMargins.top, x: &x)
            
            let rightKeyWidth: CGFloat = (leftRightGroupWidth - CGFloat(rightKeys.count - 1) * layoutConstants.buttonGapX) / CGFloat(rightKeys.count)
            let rightFrames = layoutKeyViews(keys: rightKeys, keyWidth: rightKeyWidth, layoutConstants: layoutConstants, marginTop: directionalLayoutMargins.top, x: &x)
            
            allKeys = leftKeys + middleKeys + rightKeys
            allFrames = leftFrames + middleFrames + rightFrames
        default: fatalError("Bug. Unexpected type \(keyRowView.rowId). Expecting 0..<4).")
        }
        return allFrames
    }
    
    private static func layoutKeyViews(keys: [KeyView], keyWidth: CGFloat, layoutConstants: LayoutConstants, marginTop: CGFloat, x: inout CGFloat) -> [CGRect] {
        return keys.map { key in
            let rect = CGRect(x: x, y: marginTop, width: keyWidth, height: layoutConstants.keyHeight)
            x += rect.width + layoutConstants.buttonGapX
            
            return rect
        }
    }
    
    private static func overrideLastFrame(frames: inout [CGRect], width: CGFloat) {
        if let lastFrame = frames.popLast() {
            frames.append(lastFrame.with(width: width))
        }
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
