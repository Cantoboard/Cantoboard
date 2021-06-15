//
//  AudioFeedbackProvider.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/10/21.
//

import Foundation
import AudioToolbox
import UIKit

class AudioFeedbackProvider {
    private static let clickPress: SystemSoundID = 1123
    private static let deletePress: SystemSoundID = 1155
    private static let modifierPress: SystemSoundID = 1156

    static func play(keyboardAction: KeyboardAction) {
        guard Settings.cached.isAudioFeedbackEnabled else { return }
        switch keyboardAction {
        case .none, .character(_), .rime(_), .emoji(_):
            AudioServicesPlaySystemSound(Self.clickPress)
        case .backspace, .deleteWord:
            AudioServicesPlaySystemSound(Self.deletePress)
        case .keyboardType(_), .space, .newLine:
            AudioServicesPlaySystemSound(Self.modifierPress)
        default: ()
        }
    }
    
    static let selectionGenerator = UISelectionFeedbackGenerator()

    static let lightFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    static let mediumFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    static let softFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    static let rigidFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
}
