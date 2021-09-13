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
    let colRowOrigin: CGPoint
    let colRowSize: CGSize
    var props: KeypadButtonProps
    
    // TODO HACK Remove
    private let layoutConstants = Reference(LayoutConstants.forMainScreen)
    
    init(props: KeypadButtonProps, colRowOrigin: CGPoint, colRowSize: CGSize) {
        self.colRowOrigin = colRowOrigin
        self.colRowSize = colRowSize
        self.props = props
        
        super.init(layoutConstants: layoutConstants)
        shouldDisablePopup = true
        setKeyCap(props.keyCap, keyboardIdiom: layoutConstants.ref.idiom, keyboardType: .alphabetic(.lowercased))
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
        if keyCap == .switchToEnglishMode {
            setTitle("ABC", for: .normal)
        }
        
        switch keyCap {
        case .character, .stroke:
            titleLabel?.font = .systemFont(ofSize: 26)
        default:()
        }
        
        highlightedColor = props.keyCap.keypadButtonBgHighlightedColor
    }
}
