//
//  KeyboardAction.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/11/21.
//

import Foundation
import UIKit

public enum KeyboardShiftState {
    case lowercased, uppercased, capsLocked
}

public enum KeyboardType: Equatable {
    case
    none,
    alphabetic(_ state: KeyboardShiftState),
    numeric,
    symbolic,
    emojis,
    numSymbolic
    
    var isAlphabetic: Bool {
        switch self {
        case .alphabetic: return true
        default: return false
        }
    }
}

public enum RimeChar: Character {
    case tone1 = "1"
    case tone2 = "2"
    case tone3 = "3"
    case tone4 = "4"
    case tone5 = "5"
    case tone6 = "6"
    case delimiter = "'"
    case sym = "/"
}

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
enum KeyboardAction: Equatable, ExpressibleByStringLiteral {
    case
    none,
    backspace,
    deleteWord,
    deleteWordSwipe,
    capsLock,
    character(String),
    emoji(String),
    keyboardType(KeyboardType),
    moveCursorBackward,
    moveCursorForward,
    moveCursorEnded,
    newLine,
    nextKeyboard,
    space(SpaceKeyMode),
    quote(Bool),
    shift(_ state: KeyboardShiftState),
    shiftDown, // TODO remove
    shiftUp, // TODO remove
    shiftRelax,
    rime(RimeChar),
    setCharForm(CharForm),
    toggleInputMode(InputMode),
    toggleSymbolShape,
    reverseLookup(RimeSchema),
    changeSchema(RimeSchema),
    selectCandidate(IndexPath),
    longPressCandidate(IndexPath),
    exportFile(String, String),
    enableKeyboard(Bool),
    dismissKeyboard,
    resetComposition,
    setAutoSuggestion(AutoSuggestionType, /* replaceTextLen */ Int),
    setFilter(Int),
    exit
    
    init(stringLiteral value: String) {
        self = .character(value)
    }
    
    var isShift: Bool {
        switch self {
        case .shift: return true
        default: return false
        }
    }
    
    var isSpace: Bool {
        switch self {
        case .space: return true
        default: return false
        }
    }
    
    var isKeyboardType: Bool {
        switch self {
        case .keyboardType: return true
        default: return false
        }
    }
}
