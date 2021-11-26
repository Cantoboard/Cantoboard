//
//  ButtonHintLayer.swift
//  KeyboardKit
//
//  Created by Alex Man on 2/15/21.
//

import Foundation
import UIKit

class KeyHintLayer: CATextLayer {
    static let fontSizePerHeight: CGFloat = 10 / "＠".size(withFont: UIFont.systemFont(ofSize: 10)).height
    static let recommendedHeightRatio: CGFloat = 0.24
    
    static let buttonFloatingInsets = UIEdgeInsets(top: 0.5, left: 1, bottom: 1, right: 0.5)
    static let topRightInsets = UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 2.5)
    
    private var contentSize: CGSize = .zero
    
    override init() {
        super.init()
        
        actions = CALayer.disableAnimationActions
        
        allowsFontSubpixelQuantization = true
        contentsScale = UIScreen.main.scale
    }
    
    func setup(keyCap: KeyCap, hintText: String) {
        string = hintText
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not supported.")
    }
}
