//
//  KeyboardViewLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/24/21.
//

import Foundation

protocol KeyboardViewLayout {
    static var letters: [[[KeyCap]]] { get };
    static var numbersHalf: [[[KeyCap]]] { get };
    static var symbolsHalf: [[[KeyCap]]] { get };
    static var numbersFull: [[[KeyCap]]] { get };
    static var symbolsFull: [[[KeyCap]]] { get };
}

class PhoneKeyboardViewLayout : KeyboardViewLayout {
    static let letters: [[[KeyCap]]] = [
        [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]],
        [["a", "s", "d", "f", "g", "h", "j", "k", "l"]],
        [[.shift(.lowercased)], ["z", "x", "c", "v", "b", "n", "m"], [.backspace]],
        [[.keyboardType(.numeric), .nextKeyboard], [.space(.space)], [.contextualSymbols(.english), .returnKey(.default)]]
    ]
    
    static let numbersHalf: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]],
        [["-", "/", ":", ";", "(", ")", .currency, "\"", "「", "」"]],
        [[.keyboardType(.symbolic)], [".", ",", "、", "&", "?", "!", "’"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], ["@", .returnKey(.default)]]
    ]
    
    static let symbolsHalf: [[[KeyCap]]] = [
        [["[", "]", "{", "}", "#", "%", "^", "*", "+", "="]],
        [["_", "—", "\\", "|", "~", "<", ">", "«", "»", "•"]],
        [[.keyboardType(.numeric)], [".", ",", "、", "^_^", "?", "!", "’"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], [.returnKey(.default)]]
    ]
    
    static let numbersFull: [[[KeyCap]]] = [
        [["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]],
        [["－", "／", "：", "；", "（", "）", .currency, "＂", "「", "」"]],
        [[.keyboardType(.symbolic)], ["。", "，", "、", "＆", "？", "！", "＇"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], ["＠", .returnKey(.default)]]
    ]
    
    static let symbolsFull: [[[KeyCap]]] = [
        [["［", "］", "｛", "｝", "＃", "％", "＾", "＊", "＋", "＝"]],
        [["＿", "—", "＼", "｜", "～", "〈", "〉", "《", "》", "•"]],
        [[.keyboardType(.numeric)], ["。", "，", "、", "^_^", "？", "！", "＇"], [.backspace]],
        [[.keyboardType(.alphabetic(.lowercased)), .nextKeyboard], [.space(.space)], [.returnKey(.default)]]
    ]
}

class PadKeyboardViewLayout : KeyboardViewLayout {
    static let letters: [[[KeyCap]]] = [
        [["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", .backspace]],
        [["a", "s", "d", "f", "g", "h", "j", "k", "l", .returnKey(.default)]],
        [[.shift(.lowercased), "z", "x", "c", "v", "b", "n", "m", ",", ".", .shift(.lowercased)]],
        [[.keyboardType(.numeric), .nextKeyboard], [.space(.space)], [.contextualSymbols(.english), .keyboardType(.numeric), .dismissKeyboard]]
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
}
