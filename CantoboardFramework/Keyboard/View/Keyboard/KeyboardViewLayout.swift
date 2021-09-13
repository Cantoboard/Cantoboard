//
//  KeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/24/21.
//

import Foundation
import UIKit

protocol KeyboardViewLayout {
    static var numOfRows: Int { get };
    
    static var letters: [[[KeyCap]]] { get };
    static var numbersHalf: [[[KeyCap]]] { get };
    static var symbolsHalf: [[[KeyCap]]] { get };
    static var numbersFull: [[[KeyCap]]] { get };
    static var symbolsFull: [[[KeyCap]]] { get };
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect]
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat
}

class CommonContextualKeys {
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap {
        switch key {
        case .symbol:
            let keyHint = "符"
            switch keyboardState.keyboardContextualType {
            case .chinese: return .character("，", keyHint, ["。", "，", "？", "！", ".", ",", KeyCap(rime: .sym)])
            case .english: return .character(",", keyHint, [".", ",", "?", "!", "。", "，", KeyCap(rime: .sym)])
            case .rime: return .rime(.delimiter, keyHint, [KeyCap(rime: .delimiter), ".", ",", "?", "!"])
            case .url: return .character(".", "/", ["/", ".", ".com", ".net", ".org", ".edu", KeyCap(rime: .delimiter)])
            }
        case ",": return keyboardState.keyboardContextualType.isEnglish ? "," : "，"
        case ".": return keyboardState.keyboardContextualType.isEnglish ? "." : "。"
        default: fatalError("Unexpected ContextualKey \(key) for \(keyboardState)")
        }
    }
}

extension LayoutIdiom {
    var keyboardViewLayout: KeyboardViewLayout.Type {
        switch self {
        case .phone: return PhoneKeyboardViewLayout.self
        case .pad(.padShort): return PadShortKeyboardViewLayout.self
        case .pad(.padFull4Rows): return PadFull4RowsKeyboardViewLayout.self
        case .pad(.padFull5Rows): return PadFull5RowsKeyboardViewLayout.self
        }
    }
}
