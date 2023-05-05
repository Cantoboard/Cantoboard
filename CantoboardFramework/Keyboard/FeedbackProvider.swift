//
//  AudioFeedbackProvider.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/10/21.
//

import Foundation
import AudioToolbox
import UIKit

class FeedbackProvider {
    private static let clickPress: SystemSoundID = 1123
    private static let deletePress: SystemSoundID = 1155
    private static let modifierPress: SystemSoundID = 1156

    static func play(keyboardAction: KeyboardAction) {
        guard Settings.cached.isAudioFeedbackEnabled else { return }
        switch keyboardAction {
        case .keyboardType, .space, .toggleTenKeysSpecialization, .newLine, .shift, .character("\t"), .toggleInputMode, .nextKeyboard, .dismissKeyboard:
            AudioServicesPlaySystemSound(Self.modifierPress)
        case .none, .character(_), .quote(_), .rime(_), .emoji(_):
            AudioServicesPlaySystemSound(Self.clickPress)
        case .backspace, .deleteWord:
            AudioServicesPlaySystemSound(Self.deletePress)
        default: ()
        }
    }
    
    static let selectionFeedback = UISelectionFeedbackGenerator()

    static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
}
