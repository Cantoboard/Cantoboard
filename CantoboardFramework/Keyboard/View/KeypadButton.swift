//
//  KeypadButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/15/21.
//

import Foundation
import UIKit

class KeypadButton: KeyView {
    let colRowOrigin: CGPoint
    let colRowSize: CGSize
    var props: KeypadButtonProps
    
    init(props: KeypadButtonProps, colRowOrigin: CGPoint, colRowSize: CGSize) {
        self.colRowOrigin = colRowOrigin
        self.colRowSize = colRowSize
        self.props = props
        
        super.init()
        shouldDisablePopup = true
        keyCap = props.keyCap
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getSize(layoutConstants: LayoutConstants) -> CGSize {
        let unitSize = layoutConstants.keypadButtonUnitSize
        let numOfColumns = colRowSize.width
        let numOfRows = colRowSize.height
        return CGSize(
            width: unitSize.width * numOfColumns + layoutConstants.buttonGap * (numOfColumns - 1),
            height: unitSize.height * numOfRows + layoutConstants.buttonGap * (numOfRows - 1))
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
