//
//  KeypadButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/15/21.
//

import Foundation
import UIKit

// TODO Don't use KeyView here
class KeypadButton: KeyView {
    var colRowOrigin: CGPoint = .zero
    var colRowSize: CGSize = CGSize(width: 1, height: 1)
    var autoSuggestionOverride: AutoSuggestionType?
    
    // TODO HACK Remove
    private let layoutConstants = Reference(LayoutConstants.forMainScreen)
    
    init() {
        super.init(layoutConstants: layoutConstants)
        shouldDisablePreview = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getSize(layoutConstants: LayoutConstants) -> CGSize {
        let unitSize = layoutConstants.keypadButtonUnitSize
        let numOfColumns = colRowSize.width
        let numOfRows = colRowSize.height
        return CGSize(
            width: unitSize.width * numOfColumns + layoutConstants.buttonGapX * (numOfColumns - 1),
            height: unitSize.height * numOfRows + layoutConstants.buttonGapX * (numOfRows - 1))
    }
    
    override internal func setupView() {
        super.setupView()
        if case .toggleInputMode = keyCap {
            setTitle(isKeyEnabled ? "ABC" : "", for: .normal)
        }
        
        switch keyCap {
        case .character, .stroke:
            titleLabel?.font = .systemFont(ofSize: 26)
        default:()
        }
    }
    
    override func dispatchKeyAction(_ action: KeyboardAction, _ delegate: KeyboardViewDelegate) {
        super.dispatchKeyAction(action, delegate)
        if let autoSuggestionOverride = autoSuggestionOverride {
            let replaceTextLen: Int
            switch keyCap {
            case .combo(let items): replaceTextLen = items[safe: 0]?.count ?? 0
            default: replaceTextLen = keyCap.buttonText?.count ?? 0
            }
            delegate.handleKey(.setAutoSuggestion(autoSuggestionOverride, replaceTextLen))
        }
    }
}
