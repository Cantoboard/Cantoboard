//
//  HighlightableButton.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/15/21.
//

import Foundation
import UIKit

class HighlightableButton: UIButton {
    private var originalBackgroundColor: UIColor?
    var highlightedColor: UIColor? {
        didSet {
            setupBackgroundColor()
        }
    }
    
    override var backgroundColor: UIColor? {
        get { super.backgroundColor }
        set {
            if super.backgroundColor != newValue {
                originalBackgroundColor = newValue
                setupBackgroundColor()
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            setupBackgroundColor()
        }
    }
    
    var isGrayed: Bool = false {
        didSet {
            setupBackgroundColor()
        }
    }
    
    var shadowColor: UIColor? {
        didSet {
            layer.shadowColor = shadowColor?.resolvedColor(with: traitCollection).cgColor ?? nil
        }
    }
    
    var highlightedShadowColor: UIColor? {
        didSet {
            setupBackgroundColor()
        }
    }
    
    private func setupBackgroundColor() {
        if isGrayed {
            super.backgroundColor = ButtonColor.keyGrayedColor
            shadowColor = ButtonColor.keyShadowColor
        } else if !isHighlighted {
            super.backgroundColor = originalBackgroundColor
            shadowColor = ButtonColor.keyShadowColor
        } else {
            super.backgroundColor = highlightedColor ?? originalBackgroundColor
            shadowColor = highlightedShadowColor ?? ButtonColor.keyShadowColor
        }
    }
    
}
