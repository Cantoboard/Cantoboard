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
enum SpaceKeyMode: String {
    case space = "space"
    case select = "select"
    case nextPage = "next page"
}

enum ReturnKeyType: Int {
    case confirm = -1
    case `default` = 0
    case go = 1
    case google = 2
    case join = 3
    case next = 4
    case route = 5
    case search = 6
    case send = 7
    case yahoo = 8
    case done = 9
    case emergencyCall = 10

    @available(iOS 9.0, *)
    case `continue` = 11
    
    public init(_ returnKeyType: UIReturnKeyType) {
        self = ReturnKeyType(rawValue: returnKeyType.rawValue) ?? .default
    }
}

enum KeyCap: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    capsLock,
    character(String),
    characterWithConditioanlPopup(String),
    cangjie(String),
    stroke(String),
    emoji(String),
    keyboardType(KeyboardType),
    returnKey(ReturnKeyType),
    nextKeyboard,
    space(SpaceKeyMode),
    shift(_ state: KeyboardShiftState),
    rime(RimeChar),
    contextualSymbols(ContextualType),
    reverseLookup(RimeSchema),
    changeSchema(RimeSchema),
    switchToEnglishMode,
    exportFile(String, String),
    currency,
    exit
    
    private static let cangjieKeyCaps = ["日", "月", "金", "木", "水", "火", "土", "竹", "戈", "十", "大", "中", "一", "弓", "人", "心", "手", "口", "尸", "廿", "山", "女", "田", "難", "卜", "符"]
    
    public init(stringLiteral value: String) {
        self = .character(value)
    }
    
    var action: KeyboardAction {
        switch self {
        case .none: return .none
        case .backspace: return .backspace
        case .capsLock: return .capsLock
        case .character(let c): return .character(c)
        case .characterWithConditioanlPopup(let c): return .character(c)
        case .cangjie(let c): return .character(c)
        case .stroke(let c): return .character(c)
        case .emoji(let e): return .emoji(e)
        case .keyboardType(let type): return .keyboardType(type)
        case .returnKey: return .newLine
        case .nextKeyboard: return .nextKeyboard
        case .space: return .space
        case .shift(let shiftState): return .shift(shiftState)
        case .rime(let rc): return .rime(rc)
        case .contextualSymbols(.chinese): return "，"
        case .contextualSymbols(.english): return ","
        case .contextualSymbols(.rime): return .rime(.delimiter)
        case .contextualSymbols(.url): return "."
        case .reverseLookup(let s): return .reverseLookup(s)
        case .changeSchema(let s): return .changeSchema(s)
        case .switchToEnglishMode: return .toggleInputMode
        case .exportFile(let namePrefix, let path): return .exportFile(namePrefix, path)
        case .exit: return .exit
        case .currency: return .character("BUG")
        }
    }
    
    var buttonFont: UIFont {
        switch self {
        case .keyboardType(.symbolic), .returnKey(.emergencyCall): return .systemFont(ofSize: 12)
        case .rime, "^_^", .keyboardType, .returnKey, .space, .contextualSymbols(.rime): return .systemFont(ofSize: 16)
        default: return .systemFont(ofSize: 22)
        }
    }
    
    var popupFont: UIFont {
        switch self {
        case .reverseLookup, .rime(.delimiter), .rime(.sym): return .systemFont(ofSize: 24)
        case .exportFile, .exit: return .systemFont(ofSize: 12)
        case .rime, "……", "⋯⋯", "——", "^_^", ".com", ".net", ".org", ".edu": return .systemFont(ofSize: 16)
        default: return .systemFont(ofSize: 30)
        }
    }
    
    var buttonFontStyle: UIFont.TextStyle {
        switch self {
        case .character, .characterWithConditioanlPopup, .cangjie, .emoji, .contextualSymbols: return .title2
        case .keyboardType(.emojis): return .title1
        default: return .body
        }
    }
    
    var buttonBgColor: UIColor {
        switch self {
        case .character, .characterWithConditioanlPopup, .cangjie, .stroke, .space, .contextualSymbols: return ButtonColor.inputKeyBackgroundColor
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedBackgroundColor
        case .returnKey(.continue), .returnKey(.next), .returnKey(.default), .returnKey(.confirm): return ButtonColor.systemKeyBackgroundColor
        case .returnKey: return UIColor.systemBlue
        default: return ButtonColor.systemKeyBackgroundColor
        }
    }
    
    var buttonBgHighlightedColor: UIColor? {
        switch self {
        case .character, .characterWithConditioanlPopup, .cangjie, .contextualSymbols, .shift(.uppercased), .shift(.capsLocked): return nil
        case .space: return ButtonColor.spaceKeyHighlightedBackgroundColor
        default: return ButtonColor.systemHighlightedKeyBackgroundColor
        }
    }
    
    var keypadButtonBgHighlightedColor: UIColor? {
        switch self {
        case .keyboardType, .backspace, .none, .returnKey: return ButtonColor.systemHighlightedKeyBackgroundColor
        default: return ButtonColor.spaceKeyHighlightedBackgroundColor
        }
    }
    
    var buttonFgColor: UIColor {
        switch self {
        case .returnKey(.go), .returnKey(.search): return .white
        case .shift(.uppercased), .shift(.capsLocked): return ButtonColor.shiftKeyHighlightedForegroundColor
        case .returnKey(.continue), .returnKey(.next), .returnKey(.default), .returnKey(.confirm): return ButtonColor.keyForegroundColor
        case .returnKey: return .white
        default: return ButtonColor.keyForegroundColor
        }
    }
    
    var buttonHintFgColor: UIColor {
        return ButtonColor.keyHintColor
    }
    
    // TODO Return images < iOS 12
    var buttonImage: UIImage? {
        switch self {
        case .backspace: return ButtonImage.backspace
        case .nextKeyboard: return ButtonImage.globe
        case .shift(.lowercased): return ButtonImage.shift
        case .shift(.uppercased): return ButtonImage.shiftFilled
        case .shift(.capsLocked): return ButtonImage.capLockFilled
        // case .keyboardType(.numeric): return ButtonImage.oneTwoThree
        default: return nil
        }
    }
    
    var buttonText: String? {
        switch self {
        case .characterWithConditioanlPopup(let text): return text
        case .returnKey(.confirm): return LocalizedStrings.keyTitleConfirm
        case .returnKey(.go): return LocalizedStrings.keyTitleGo
        case .returnKey(.next): return LocalizedStrings.keyTitleNext
        case .returnKey(.send): return LocalizedStrings.keyTitleSend
        case .returnKey(.search), .returnKey(.google), .returnKey(.yahoo): return LocalizedStrings.keyTitleSearch
        case .returnKey(.continue): return LocalizedStrings.keyTitleContinue
        case .returnKey(.done): return LocalizedStrings.keyTitleDone
        case .returnKey(.emergencyCall): return LocalizedStrings.keyTitleSOS
        case .returnKey(.join): return LocalizedStrings.keyTitleJoin
        case .returnKey(.route): return LocalizedStrings.keyTitleRoute
        case .returnKey: return LocalizedStrings.keyTitleReturn
        case .space(.nextPage): return LocalizedStrings.keyTitleNextPage
        case .space(.select): return LocalizedStrings.keyTitleSelect
        case .space(.space): return LocalizedStrings.keyTitleSpace
        case .keyboardType(.numeric): return "123"
        case .keyboardType(.symbolic): return "#+="
        case .keyboardType(.alphabetic): return "ABC"
        case .rime(.tone1): return "陰平"
        case .rime(.tone2): return "陰上"
        case .rime(.tone3): return "陰去"
        case .rime(.tone4): return "陽平"
        case .rime(.tone5): return "陽上"
        case .rime(.tone6): return "陽去"
        case .rime(.delimiter): return "分"
        case .rime(.sym): return "符"
        case .reverseLookup(let schema): return schema.signChar
        case .changeSchema(let schema): return schema.shortName
        case .switchToEnglishMode: return "英文"
        case .contextualSymbols(.chinese): return "，"
        case .contextualSymbols(.english): return ","
        case .contextualSymbols(.rime): return "分"
        case .contextualSymbols(.url): return "."
        case "（": return "("
        case "）": return ")"
        case "「": return "「　"
        case "」": return "  」"
        case "〈": return "〈　"
        case "〉": return "  〉"
        case "《": return "《　"
        case "》": return "  》"
        case "［": return "["
        case "］": return "]"
        case "｛": return "{"
        case "｝": return "}"
        case .character(let text): return text
        case .cangjie(let c):
            guard let asciiCode = c.lowercased().first?.asciiValue else { return nil }
            let letterIndex = Int(asciiCode - "a".first!.asciiValue!)
            return Self.cangjieKeyCaps[safe: letterIndex] ?? c
        case .stroke(let c):
            switch c.lowercased() {
            case "h": return "一"
            case "s": return "丨"
            case "p": return "丿"
            case "n": return "丶"
            case "z": return "乙"
            default: return nil
            }
        case .exportFile(let namePrefix, _): return namePrefix.capitalized
        case .exit: return "Exit"
        default: return nil
        }
    }
    
    var buttonHint: String? {
        if Settings.cached.toneInputMode == .longPress {
            switch self {
            case .characterWithConditioanlPopup("F"), .characterWithConditioanlPopup("f"): return "4"
            case .characterWithConditioanlPopup("G"), .characterWithConditioanlPopup("g"): return "5"
            case .characterWithConditioanlPopup("H"), .characterWithConditioanlPopup("h"): return "6"
            case .characterWithConditioanlPopup("C"), .characterWithConditioanlPopup("c"): return "1"
            case .characterWithConditioanlPopup("V"), .characterWithConditioanlPopup("v"): return "2"
            case .characterWithConditioanlPopup("B"), .characterWithConditioanlPopup("b"): return "3"
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
            case "V", "v": return "1/4"
            case "X", "x": return "2/5"
            case "Q", "q": return "3/6"
            default: ()
            }
        }
        
        switch self {
        case .characterWithConditioanlPopup("R"), .characterWithConditioanlPopup("r"): return "反"
        case .contextualSymbols(.chinese), .contextualSymbols(.english): return "符"
        case .contextualSymbols(.url): return "/"
        case .space: return "Cantoboard"
        default: return barHint
        }
    }
    
    var barHint: String? {
        switch self {
        case "，", "。", "．", "？", "！",
             "－", "／", "：", "；", "（", "）", "＠", "、", "⋯", "⋯⋯", "＆",
             "１", "２", "３", "４", "５", "６", "７", "８", "９", "０",
             "［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝",
             "＿", "＼", "｜", "～", "〈", "＜", "＞", "〉",
             "＄", "＂", "＇": return "全"
        default: return nil
        }
    }
    
    var buttonHintFontSize: CGFloat {
        let layoutConstants = LayoutConstants.forMainScreen
        if Settings.cached.toneInputMode == .vxq {
            switch self {
            case .character("V"), .character("v"),
                 .character("X"), .character("x"),
                 .character("Q"), .character("q"):
                return layoutConstants.smallKeyHintFontSize
            default: ()
            }
        }
        
        return layoutConstants.mediumKeyHintFontSize
    }
    
    func buttonWidth(_ layoutConstants: LayoutConstants) -> CGFloat {
        switch self {
        case .shift, .capsLock, .keyboardType(.symbolic), .backspace:
            return layoutConstants.shiftButtonWidth
        case .returnKey:
            return 1.5 * layoutConstants.systemButtonWidth
        case .character, .characterWithConditioanlPopup, .cangjie, .contextualSymbols:
            return layoutConstants.keyButtonWidth
        default:
            return layoutConstants.systemButtonWidth
        }
    }
    
    var hasPopup: Bool {
        switch self {
        case .character, .characterWithConditioanlPopup, .contextualSymbols, .cangjie: return true
        // For debugging
        case .keyboardType(.emojis): return true
        default: return false
        }
    }
    
    private static var logsPath: String = DataFileManager.logsDirectory
    private static let userDataPath: String = DataFileManager.userDataDirectory
    
    var childrenKeyCaps: [KeyCap] {
        switch self {
        case .characterWithConditioanlPopup(let c):
            switch c {
            case "F", "f": return [.character(c), .rime(RimeChar.tone4)]
            case "G", "g": return [.character(c), .rime(RimeChar.tone5)]
            case "H", "h": return [.character(c), .rime(RimeChar.tone6)]
            case "C", "c": return [.character(c), .rime(RimeChar.tone1)]
            case "V", "v": return [.character(c), .rime(RimeChar.tone2)]
            case "B", "b": return [.character(c), .rime(RimeChar.tone3)]
            case "R", "r": return [.character(c), .reverseLookup(.cangjie), .reverseLookup(.quick), .reverseLookup(.mandarin), .reverseLookup(.loengfan), .reverseLookup(.stroke)]
            default: return [self]
            }
        case .contextualSymbols(.chinese): return ["。", "，", "？", "！", ".", ",", .rime(.sym)]
        case .contextualSymbols(.english): return [".", ",", "?", "!", "。", "，", .rime(.sym)]
        case .contextualSymbols(.rime): return [self, ".", ",", "?", "!"]
        case .contextualSymbols(.url): return ["/", ".", ".com", ".net", ".org", ".edu", .rime(.delimiter)]
        case .keyboardType(.emojis): return [.exportFile("user", Self.userDataPath), .exportFile("logs", Self.logsPath), .exit]
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
        case "\"": return ["\"", "＂", "”", "“", "„", "»", "«"]
        case "「": return ["「", "『", "“", "‘"]
        case "」": return ["」", "』", "”", "’"]
        // 123 3rd row
        case ".": return [".", "。", "．", "…", "⋯", "⋯⋯"]
        case ",": return [",", "，"]
        case "､": return ["､", "、"]
        case "&": return ["＆", "&", "§"]
        case "?": return ["?", "？", "¿"]
        case "!": return ["!", "！", "¡"]
        case "’": return ["’", "'", "＇", "‘", "`"]
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
        case "«": return ["«", "《"]
        case "»": return ["»", "》"]
        case "•": return ["•", "·", "．", "°"]
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
        case "＂": return ["＂", "\"", "”", "“", "c", "»", "«"]
        // 123 3rd row full width
        case "。": return ["。", ".", "．", "…", "⋯", "⋯⋯"]
        case "，": return ["，", ", "]
        case "＆": return ["&", "＆", "§"]
        case "、": return ["､", "、"]
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
        case "《": return ["《", "«"]
        case "》": return ["》", "»"]
        case "·": return ["·", "．", "•", "°"]
        case .character(let c) where c.first?.isCurrencySymbol ?? false:
            var currencyLists: [KeyCap] =  ["¢", "$", "€", "£", "¥", "₩", "₽", "＄"]
            let localCurrencySymbolKeyCap: KeyCap = .character(NSLocale.current.currencySymbol ?? "$")
            currencyLists.removeAll(where: { $0 == localCurrencySymbolKeyCap })
            currencyLists.insert(localCurrencySymbolKeyCap, at: currencyLists.count / 2 - 1)
            return currencyLists
        default: return [self]
        }
    }
    
    var defaultChildKeyCap: KeyCap? {
        self
    }
}

let FrameworkBundle = Bundle(for: KeyView.self)

class ButtonImage {
    static let globe = UIImage(named: "globe", in: Bundle(for: ButtonImage.self), with: nil)
    static let backspace = UIImage(named: "delete.left", in: Bundle(for: ButtonImage.self), with: nil)
    static let shift = UIImage(named: "shift", in: Bundle(for: ButtonImage.self), with: nil)
    static let shiftFilled = UIImage(named: "shift.fill", in: Bundle(for: ButtonImage.self), with: nil)
    static let capLockFilled = UIImage(named: "capslock.fill", in: Bundle(for: ButtonImage.self), with: nil)
    static let emojiKeyboardLight = UIImage(named: "face.smiling", in: Bundle(for: ButtonImage.self), with: UIImage.SymbolConfiguration(pointSize: 18))
    static let emojiKeyboardDark = UIImage(named: "face.smiling.fill", in: Bundle(for: ButtonImage.self), with: UIImage.SymbolConfiguration(pointSize: 18))
    static let paneCollapseButtonImage = UIImage(named: "chevron.up", in: Bundle(for: ButtonImage.self), with: nil)
    static let paneExpandButtonImage = UIImage(named: "chevron.down", in: Bundle(for: ButtonImage.self), with: nil)
    // static let oneTwoThree = UIImage(systemName: "textformat.123", in: Bundle(for: ButtonImage.self), with: nil)
}

class ButtonColor {
    static let systemKeyBackgroundColor = UIColor(named: "systemKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let inputKeyBackgroundColor = UIColor(named: "inputKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let keyForegroundColor = UIColor(named: "keyForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let keyHintColor = UIColor(named: "keyHintColor", in: FrameworkBundle, compatibleWith: nil)!
    static let popupBackgroundColor = UIColor(named: "popupBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let keyShadowColor = UIColor(named: "keyShadowColor", in: FrameworkBundle, compatibleWith: nil)!
    static let shiftKeyHighlightedBackgroundColor = UIColor(named: "shiftKeyHighlightedBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let shiftKeyHighlightedForegroundColor = UIColor(named: "shiftKeyHighlightedForegroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let spaceKeyHighlightedBackgroundColor = UIColor(named: "spaceKeyHighlightedBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
    static let systemHighlightedKeyBackgroundColor = UIColor(named: "systemHighlightedKeyBackgroundColor", in: FrameworkBundle, compatibleWith: nil)!
}
