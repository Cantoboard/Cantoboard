//
//  BaseKeyboardView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func handleKey(_ action: KeyboardAction)
    func handleInputModeList(from: UIView, with: UIEvent)
}

protocol BaseKeyboardView: UIView {
    var layoutConstants: Reference<LayoutConstants> { get }
    var candidateOrganizer: CandidateOrganizer? { get set }
    
    var delegate: KeyboardViewDelegate? { get set }
    var state: KeyboardState { get set }
    func scrollCandidatePaneToNextPageInRowMode()
    func setPreserveCandidateOffset()
    func changeCandidatePaneMode(_ mode: CandidatePaneView.Mode)
}
