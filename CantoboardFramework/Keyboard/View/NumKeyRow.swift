//
//  NumKeyRow.swift
//  CantoboardFramework
//
//  Created by Alex Man on 11/10/21.
//

import Foundation
import UIKit

class NumKeyRow: UIView {
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<NumKeyRow>()
    
    private var layoutConstants: Reference<LayoutConstants>
    private var numKeys: [Weak<KeyView>]!
    
    private var _keyboardState: KeyboardState
    var keyboardState: KeyboardState {
        get { _keyboardState }
        set {
            numKeys.forEach {
                guard let keyView = $0.ref else { return }
                
                keyView.setKeyCap(keyView.keyCap, keyboardState: newValue)
                keyView.isKeyEnabled = newValue.enableState == .enabled
            }
            _keyboardState = newValue
        }
    }
    
    init(keyboardState: KeyboardState, layoutConstants: Reference<LayoutConstants>) {
        _keyboardState = keyboardState
        self.layoutConstants = layoutConstants

        super.init(frame: .zero)
        
        numKeys = (1...10).map { d in
            let keyCap = KeyCap(String(d % 10))
            let keyView = KeyView(layoutConstants: layoutConstants)
            keyView.setKeyCap(keyCap, keyboardState: keyboardState)
            keyView.shouldDisablePopup = true
            addSubview(keyView)
            return Weak(keyView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {        
        let minX: CGFloat = layoutConstants.ref.keyboardViewInsets.left
        let maxX: CGFloat = bounds.width
        let gapX: CGFloat = layoutConstants.ref.buttonGapX
        
        let keyWidth: CGFloat = (maxX - minX - CGFloat(numKeys.count - 1) * gapX) / CGFloat(numKeys.count)
        
        var hitframeX: CGFloat = 0
        var x = minX
        for i in 0..<numKeys.count {
            guard let keyView = numKeys[i].ref else { return }
            
            keyView.frame = CGRect(x: x, y: 0, width: keyWidth, height: bounds.height)
            let hitTestExtraWidth = i == 0 ? minX + gapX / 2 : gapX
            keyView.hitTestFrame = CGRect(x: hitframeX, y: 0, width: keyWidth + hitTestExtraWidth, height: bounds.height)
            x += keyWidth + gapX
            hitframeX = x - gapX / 2
        }
    }
}

extension NumKeyRow {
    // Forward all touch events to the superview.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.superview?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.superview?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.superview?.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.superview?.touchesCancelled(touches, with: event)
    }
}
