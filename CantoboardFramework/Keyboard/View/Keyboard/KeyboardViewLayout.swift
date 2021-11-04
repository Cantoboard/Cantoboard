//
//  KeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/24/21.
//

import Foundation
import UIKit

enum GroupLayoutDirection {
    case left, middle, right
}

protocol KeyboardViewLayout {
    static var numOfRows: Int { get };
    
    static var letters: [[[KeyCap]]] { get };
    static var numbersHalf: [[[KeyCap]]] { get };
    static var symbolsHalf: [[[KeyCap]]] { get };
    static var numbersFull: [[[KeyCap]]] { get };
    static var symbolsFull: [[[KeyCap]]] { get };
    
    static func layoutKeyViews(keyRowView: KeyRowView, leftKeys: [KeyView], middleKeys: [KeyView], rightKeys: [KeyView], layoutConstants: LayoutConstants) -> [CGRect]
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap?
    static func getKeyHeight(atRow: Int, layoutConstants: LayoutConstants) -> CGFloat
    static func getSwipeDownKeyCap(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap?
    static func isSwipeDownKeyShiftMorphing(keyCap: KeyCap) -> Bool
}

class CommonContextualKeys {
    static func getContextualKeys(key: ContextualKey, keyboardState: KeyboardState) -> KeyCap? {
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
        case ".com" where keyboardState.keyboardContextualType == .url: // For iPad Pro 12.9"
            return .character(".com", nil, [".net", ".org", ".edu", ".com", ".hk", ".tw", ".mo", ".cn", ".us"])
        default: return nil
        }
    }
}

class CommonSwipeDownKeys {
    static func getSwipeDownKeyCapForPadShortOrFull4Rows(keyCap: KeyCap, keyboardState: KeyboardState) -> KeyCap? {
        let isInChineseContextualMode = !keyboardState.keyboardContextualType.isEnglish
        let keyCapCharacter: String?
        switch keyCap {
        case .character(let c, _, _), .cangjie(let c, _): keyCapCharacter = c.lowercased()
        case .currency: keyCapCharacter = "$"
        case .singleQuote: keyCapCharacter = "'"
        case .doubleQuote: keyCapCharacter = "\""
        default: keyCapCharacter = nil
        }
        switch keyCapCharacter {
        case "q": return "1"
        case "w": return "2"
        case "e": return "3"
        case "r": return "4"
        case "t": return "5"
        case "y": return "6"
        case "u": return "7"
        case "i": return "8"
        case "o": return "9"
        case "p": return "0"
        case "a": return "@"
        case "s": return "#"
        case "d": return .currency
        case "f": return isInChineseContextualMode ? "／" : "/"
        case "g": return isInChineseContextualMode ? "（" : "("
        case "h": return isInChineseContextualMode ? "）" : ")"
        case "j": return isInChineseContextualMode ? "「" : "｢"
        case "k": return isInChineseContextualMode ? "」" : "｣"
        case "l": return .singleQuote
        case "z": return "%"
        case "x": return "-"
        case "c": return isInChineseContextualMode ? "~" : "～"
        case "v": return isInChineseContextualMode ? "⋯" : "…"
        case "b": return isInChineseContextualMode ? "、" : "､"
        case "n": return isInChineseContextualMode ? "；" : ";"
        case "m": return isInChineseContextualMode ? "：" : ":"
        case ",": return "!"
        case ".": return "?"
        case "，": return "！"
        case "。": return "？"
        case "@": return "^"
        case "#": return "_"
        case "$": return isInChineseContextualMode ? "｜" : "|"
        case "/": return "\\"
        case "／": return "＼"
        case "(": return "["
        case ")": return "]"
        case "（": return "［"
        case "）": return "］"
        case "｢": return "{"
        case "｣": return "}"
        case "「": return "｛"
        case "」": return "｝"
        case "'": return .doubleQuote
        case "%": return "*"
        case "-", "–": return "&"
        case "~", "～": return "+"
        case "…", "⋯": return "="
        case "､", "、": return "·"
        case ";": return "<"
        case "；": return "《"
        case ":": return ">"
        case "：": return "》"
        default: return nil
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
