//
//  KeyCap.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

/**
 This action enum specifies all currently supported keyboard
 actions and their standard behavior.
 
 Most actions have a standard behavior for a certain gesture
 when their used in system keyboards. This standard behavior
 is provided through `standardInputViewControllerAction` and
 `standardTextDocumentProxyAction`. Keyboard action handlers
 can choose to use these standard actions or ignore them.
 
 Many actions require manual handling since they do not have
 universal, app-agnostic behaviors. For instance, the `image`
 action depends on what you want to do with the tapped image.
 Actions like these are a way for you to express your intent,
 but require manual handling in a custom action handler.
*/
enum KeyCap: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    capsLock,
    character(String),
    characterWithTone(String),
    emoji(String),
    keyboardType(KeyboardType),
    newLine,
    nextKeyboard,
    space,
    shift(_ state: KeyboardShiftState),
    rime(RimeChar),
    contexualSymbols(ContextualType),
    charForm(CharForm)
    
    public init(stringLiteral value: String) {
        self = .character(value)
    }
    
    func getAction(/* type, state*/) -> KeyboardAction {
        switch self {
        case .none: return .none
        case .backspace: return .backspace
        case .capsLock: return .capsLock
        case .character(let c): return .character(c)
        case .characterWithTone(let c): return .character(c)
        case .emoji(let e): return .emoji(e)
        case .keyboardType(let type): return .keyboardType(type)
        case .newLine: return .newLine
        case .nextKeyboard: return .nextKeyboard
        case .space: return .space
        case .shift(let shiftState): return .shift(shiftState)
        case .rime(let rc): return .rime(rc)
        case .contexualSymbols(.chinese): return "，"
        case .contexualSymbols(.english): return ","
        case .contexualSymbols(.rime): return .rime(.delimiter)
        case .contexualSymbols(.url): return "."
        case .charForm(let cs): return .setCharForm(cs)
        }
    }
    
    var buttonFont: UIFont {
        switch self {
        case .rime, "^_^": return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(16)
        // case .contexualSymbols(.rime): return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(18)
        default: return .preferredFont(forTextStyle: buttonFontStyle)
        }
    }
    
    var popupFont: UIFont {
        switch self {
        case .rime, "⋯⋯", "^_^", ".com", ".net", ".org", ".edu":
            return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(16)
        /*case .chineseScript, .rime(.delimiter): return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(30)*/
        default: return UIFont.preferredFont(forTextStyle: buttonFontStyle).withSize(30)
        }
    }
    
    var buttonFontStyle: UIFont.TextStyle {
        switch self {
        case .character, .characterWithTone, .emoji, .contexualSymbols: return .title2
        case .keyboardType(.emojis): return .title1
        default: return .body
        }
    }
    
    var buttonBgColor: UIColor {
        switch self {
        case .character, .characterWithTone, .space, .contexualSymbols: return ButtonColor.InputKeyBackgroundColor
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.ShiftKeyHighlightedBackgroundColor
        default: return ButtonColor.SystemKeyBackgroundColor
        }
    }
    
    var buttonFgColor: UIColor {
        if self == .shift(.uppercased) || self == .shift(.capsLocked) {
            return ButtonColor.ShiftKeyHighlightedForegroundColor
        }
        return ButtonColor.KeyForegroundColor
    }
    
    var buttonHintFgColor: UIColor {
        if self == .space { return buttonFgColor.withAlphaComponent(0.6) }
        return buttonFgColor
    }
    
    // TODO Return images < iOS 12
    var buttonImage: UIImage? {
        switch self {
        case .backspace: return ButtonImage.Backspace
        case .nextKeyboard: return ButtonImage.Globe
        case .shift(.lowercased): return ButtonImage.Shift
        case .shift(.uppercased): return ButtonImage.ShiftFilled
        case .shift(.capsLocked): return ButtonImage.CapLockFilled
        case .keyboardType(.emojis): return ButtonImage.EmojiKeyboard
        // case .keyboardType(.numeric): return ButtonImage.oneTwoThree
        default: return nil
        }
    }
    
    var buttonText: String? {
        switch self {
        case .characterWithTone(let text): return text
        case .newLine: return "return"
        case .space: return "space"
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic): return "ABC"
        case .rime(.tone1): return "陰平"
        case .rime(.tone2): return "陰上"
        case .rime(.tone3): return "陰去"
        case .rime(.tone4): return "陽平"
        case .rime(.tone5): return "陽上"
        case .rime(.tone6): return "陽去"
        case .rime(.delimiter): return "斷"
        case .contexualSymbols(.chinese): return "，"
        case .contexualSymbols(.english): return ","
        case .contexualSymbols(.rime): return "斷"
        case .contexualSymbols(.url): return "."
        case .charForm(.traditionalHK): return "繁"
        case .charForm(.simplified): return "簡"
        case "（": return "("
        case "）": return ")"
        case "「": return "「　"
        case "」": return "  」"
        case "《": return "《　"
        case "》": return "  》"
        case "［": return "["
        case "］": return "]"
        case "｛": return "{"
        case "｝": return "}"
        case .character(let text): return text
        default: return nil
        }
    }
    
    var buttonHint: String? {
        if Settings.cached.rimeSettings.toneInputMode == .longPress {
            switch self {
            case .characterWithTone("F"), .characterWithTone("f"): return "4"
            case .characterWithTone("G"), .characterWithTone("g"): return "5"
            case .characterWithTone("H"), .characterWithTone("h"): return "6"
            case .characterWithTone("C"), .characterWithTone("c"): return "1"
            case .characterWithTone("V"), .characterWithTone("v"): return "2"
            case .characterWithTone("B"), .characterWithTone("b"): return "3"
            case .rime(.tone1): return "1"
            case .rime(.tone2): return "2"
            case .rime(.tone3): return "3"
            case .rime(.tone4): return "4"
            case .rime(.tone5): return "5"
            case .rime(.tone6): return "6"
            default: ()
            }
        } else {
            switch self {
            case .character("V"), .character("v"): return "1/4"
            case .character("X"), .character("x"): return "2/5"
            case .character("Q"), .character("q"): return "3/6"
            default: ()
            }
        }
        
        switch self {
        case .contexualSymbols(.chinese), "，", "。", "？", "！",
             "－", "／", "：", "；", "（", "）", "＠", "、", "⋯", "⋯⋯", "＆",
             "１", "２", "３", "４", "５", "６", "７", "８", "９", "０",
             "［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝",
             "＿", "＼", "｜", "～", "〈", "＜", "＞", "〉",
             "￠", "＄", "€", "￡", "￥", "￦", "₽", "＂", "＇": return "全"
        case .charForm(let cs): return Settings.cached.charForm == cs ? "*" : nil
        case .space: return "Cantoboard"
        default: return nil
        }
    }
    
    var buttonHintFontSize: CGFloat {
        if Settings.cached.rimeSettings.toneInputMode == .vxq {
            switch self {
            case .character("V"), .character("v"): return 7
            case .character("X"), .character("x"): return 7
            case .character("Q"), .character("q"): return 7
            default: ()
            }
        }
        
        return 9
    }
    
    func buttonWidth(_ layoutConstants: LayoutConstants) -> CGFloat {
        switch self {
        case .shift, .capsLock, .keyboardType(.symbolic), .backspace:
            return layoutConstants.shiftButtonWidth
        case .newLine:
            return 1.5 * layoutConstants.systemButtonWidth
        case .character, .characterWithTone, .contexualSymbols:
            return layoutConstants.keyButtonWidth
        default:
            return layoutConstants.systemButtonWidth
        }
    }
    
    var hasPopup: Bool {
        switch self {
        case .character, .characterWithTone, .contexualSymbols: return true
        case .keyboardType(.emojis): return true
        default: return false
        }
    }
    
    var childrenKeyCaps: [KeyCap] {
        switch self {
        case .characterWithTone(let c):
            switch c {
            case "F", "f": return [.character(c), .rime(RimeChar.tone4)]
            case "G", "g": return [.character(c), .rime(RimeChar.tone5)]
            case "H", "h": return [.character(c), .rime(RimeChar.tone6)]
            case "C", "c": return [.character(c), .rime(RimeChar.tone1)]
            case "V", "v": return [.character(c), .rime(RimeChar.tone2)]
            case "B", "b": return [.character(c), .rime(RimeChar.tone3)]
            default: return [self]
            }
        case .contexualSymbols(.chinese): return ["。", "，", "？", "！", ".", ","]
        case .contexualSymbols(.english): return [".", ",", "?", "!", "。", "，"]
        case .contexualSymbols(.rime): return [self, ".", ",", "?", "!"]
        case .contexualSymbols(.url): return ["/", ".", ".com", ".net", ".org", ".edu", .rime(.delimiter)]
        case .keyboardType(.emojis):
            if Settings.cached.charForm != .simplified {
                return [.charForm(.traditionalHK), .charForm(.simplified)]
            } else {
                return [.charForm(.simplified), .charForm(.traditionalHK) ]
            }
        // 123 1st row
        case "1": return ["1", "一", "壹", "１", "①", "⑴", "⒈", "❶", "㊀", "㈠"]
        case "2": return ["貳", "2", "二", "２", "②", "⑵", "⒉", "❷", "㊁", "㈡"]
        case "3": return ["③", "叁", "3", "三", "３", "⑶", "⒊", "❸", "㊂", "㈢"]
        case "4": return ["⒋", "④", "肆", "4", "四", "４", "⑷", "❹", "㊃", "㈣"]
        case "5": return ["㊄", "⒌", "⑤", "伍", "5", "五", "５", "⑸", "❺", "㈤"]
        case "6": return ["❻", "⑹", "６", "六", "6", "陸", "⑥", "⒍", "㊅", "㈥"]
        case "7": return ["⑺", "７", "七", "7", "柒", "⑦", "⒎", "❼", "㊆", "㈦"]
        case "8": return ["８", "八", "8", "捌", "⑧", "⑻", "⒏", "❽", "㊇", "㈧"]
        case "9": return ["九", "9", "玖", "９", "⑨", "⑼", "⒐", "❾", "㊈", "㈨"]
        case "0": return ["0", "０", "零", "十", "拾", "⓪", "°"]
        // 123 2nd row
        case "-": return ["-", "－", "–", "—", "•"]
        case "/": return ["/", "／", "\\"]
        case ":": return [":", "："]
        case ";": return [";", "；"]
        case "(": return ["(", "（"]
        case ")": return [")", "）"]
        case "$": return ["¢", "$", "€", "£", "¥", "₩", "₽"]
        case "\"": return ["\"", "＂", "”", "“", "„", "»", "«"]
        case "「": return ["「", "『", "“", "‘"]
        case "」": return ["」", "』", "”", "’"]
        // 123 3rd row
        case ".": return [".", "。", "…", "⋯", "⋯⋯"]
        case ",": return [", ", "，"]
        case "&": return ["＆", "&", "§"]
        case "?": return ["?", "？", "¿"]
        case "!": return ["!", "！", "¡"]
        case "‘": return ["'", "＇", "’", "‘", "`"]
        // 123 4rd row
        case "@": return ["@", "＠"]
        // #+= 1st row
        case "[": return ["[", "［", "【", "〔"]
        case "]": return ["]", "］", "】", "〕"]
        case "{": return ["{", "｛"]
        case "}": return ["}", "｝"]
        case "#": return ["#", "＃"]
        case "%": return ["%", "％", "‰"]
        case "^": return ["^", "＾"]
        case "*": return ["*", "＊"]
        case "+": return ["+", "＋"]
        case "=": return ["=", "≠", "≈", "＝"]
        // #+= 2nd row
        case "_": return ["_", "＿"]
        case "\\": return ["\\", "＼"]
        case "|": return ["|", "｜"]
        case "~": return ["~", "～"]
        case "<": return ["<", "〈", "＜"]
        case ">": return [">", "〉", "＞"]
        case "•": return ["•", "·", "°"]
        // 123 1st row full width
        case "１": return ["１", "一", "壹", "1", "①", "⑴", "⒈", "❶", "㊀", "㈠"]
        case "２": return ["貳", "２", "二", "2", "②", "⑵", "⒉", "❷", "㊁", "㈡"]
        case "３": return ["③", "叁", "３", "三", "3", "⑶", "⒊", "❸", "㊂", "㈢"]
        case "４": return ["⒋", "④", "肆", "４", "四", "4", "⑷", "❹", "㊃", "㈣"]
        case "５": return ["㊄", "⒌", "⑤", "伍", "５", "五", "5", "⑸", "❺", "㈤"]
        case "６": return ["❻", "⑹", "6", "六", "６", "陸", "⑥", "⒍", "㊅", "㈥"]
        case "７": return ["⑺", "7", "七", "７", "柒", "⑦", "⒎", "❼", "㊆", "㈦"]
        case "８": return ["8", "八", "８", "捌", "⑧", "⑻", "⒏", "❽", "㊇", "㈧"]
        case "９": return ["九", "９", "玖", "9", "⑨", "⑼", "⒐", "❾", "㊈", "㈨"]
        case "０": return ["０", "0", "零", "十", "拾", "⓪", "°"]
        // 123 2nd row full width
        case "－": return ["－", "-", "–", "—", "•"]
        case "／": return ["／", "/", "\\"]
        case "：": return ["：", ":"]
        case "；": return ["；", ";"]
        case "（": return ["（", "("]
        case "）": return ["）", ")"]
        case "＄": return ["￠", "＄", "€", "￡", "￥", "￦", "₽"]
        case "＂": return ["＂", "\"", "”", "“", "c", "»", "«"]
        // 123 3rd row full width
        case "。": return ["。", ".","…", "⋯", "⋯⋯"]
        case "，": return ["，", ", "]
        case "＆": return ["&", "＆", "§"]
        case "？": return ["？", "?", "¿"]
        case "！": return ["！", "!", "¡"]
        case "＇": return ["＇", "'", "’", "‘", "｀"]
        // 123 4rd row full width
        case "＠": return ["＠", "@"]
        // #+= 1st row full width
        case "［": return ["［", "[", "【", "〔"]
        case "］": return ["］", "]", "】", "〕"]
        case "｛": return ["｛", "{"]
        case "｝": return ["｝", "}"]
        case "＃": return ["＃", "#"]
        case "％": return ["％", "%", "‰"]
        case "＾": return ["＾", "^"]
        case "＊": return ["＊", "*"]
        case "＋": return ["＋", "+"]
        case "＝": return ["＝", "=", "≠", "≈"]
        // #+= 2nd row full width
        case "＿": return ["＿", "_"]
        case "＼": return ["＼", "\\"]
        case "｜": return ["｜", "|"]
        case "～": return ["～", "~"]
        case "〈": return ["〈", "<", "＜"]
        case "〉": return ["〉", ">", "＞"]
        default: return [self]
        }
    }
    
    var defaultChildKeyCap: KeyCap? {
        self
    }
}

let FrameworkBundle = Bundle(for: KeyView.self)

class ButtonImage {
    static let Globe = UIImage(systemName: "globe")
    static let Backspace = UIImage(systemName: "delete.left")
    static let Shift = UIImage(systemName: "shift")
    static let ShiftFilled = UIImage(systemName: "shift.fill")
    static let CapLockFilled = UIImage(systemName: "capslock.fill")
    static let EmojiKeyboard = UIImage(systemName: "face.smiling", withConfiguration: UIImage.SymbolConfiguration(scale: .large))
    // static let oneTwoThree = UIImage(systemName: "textformat.123")
}


class ButtonColor {
    static let SystemKeyBackgroundColor = UIColor(named: "systemKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let InputKeyBackgroundColor = UIColor(named: "inputKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let KeyForegroundColor = UIColor(named: "keyForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let PopupBackgroundColor = UIColor(named: "PopupBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let KeyShadowColor = UIColor(named: "keyShadowColor", in: FrameworkBundle, compatibleWith: nil)!
    static let ShiftKeyHighlightedBackgroundColor = UIColor(named: "ShiftKeyHighlightedBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let ShiftKeyHighlightedForegroundColor = UIColor(named: "ShiftKeyHighlightedForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
}
