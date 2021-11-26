//
//  CompositionLabel.swift
//  CantoboardFramework
//
//  Created by Alex Man on 9/26/21.
//

import Foundation
import UIKit

class CompositionLabel: UILabel {
    static let insets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 2, right: 4)
    
    private static let caretColor: UIColor = UIColor(dynamicProvider: {
        $0.userInterfaceStyle == .dark ? UIColor.white : UIColor.darkGray
    })
    private static let caretWidth: CGFloat = 1.5
    private static let fontSizePerHeight: CGFloat = 14 / "Ag".size(withFont: UIFont.systemFont(ofSize: 14)).height

    private weak var caretView: CALayer?
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        textColor = ButtonColor.keyForegroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var composition: Composition? {
        didSet {
            if let composition = composition {
                text = composition.text
                if caretView == nil {
                    let caretView = CAShapeLayer()
                    caretView.backgroundColor = Self.caretColor.resolvedColor(with: traitCollection).cgColor
                    caretView.actions = CALayer.disableAnimationActions
                    
                    layer.addSublayer(caretView)
                    
                    self.caretView = caretView
                }
            } else {
                text = nil
                caretView?.removeFromSuperlayer()
                caretView = nil
            }
            setNeedsLayout()
            superview?.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        guard let composition = composition else { return }
        
        let textBeforeCaret = String(composition.text.prefix(composition.caretIndex))
        let textBeforeCaretSize = textBeforeCaret.size(withFont: font)
        
        font = font.withSize(Self.fontSizePerHeight * bounds.height)
        
        caretView?.frame = CGRect(
            origin: CGPoint(x: textBeforeCaretSize.width - Self.caretWidth / 2, y: 0),
            size: CGSize(width: Self.caretWidth, height: bounds.height))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        caretView?.backgroundColor = Self.caretColor.resolvedColor(with: traitCollection).cgColor
    }
    
    func getRequiredWidth(height: CGFloat) -> CGFloat {
        return text?.size(withFont: font.withSize(Self.fontSizePerHeight * height)).width ?? .zero
    }
}
