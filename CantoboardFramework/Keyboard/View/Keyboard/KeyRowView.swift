//
//  StockboardKeyRow.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/16/21.
//

import Foundation
import UIKit

class KeyRowView: UIView {
    private(set) var leftKeys, middleKeys, rightKeys: [KeyView]!
    private(set) var rowId: Int = -1
    var needsInputModeSwitchKey = false
    
    private var layoutConstants: Reference<LayoutConstants>
    
    var isEnabled: Bool = true {
        didSet {
            leftKeys.forEach { $0.isKeyEnabled = isEnabled }
            middleKeys.forEach { $0.isKeyEnabled = isEnabled }
            rightKeys.forEach { $0.isKeyEnabled = isEnabled }
        }
    }
    
    init(layoutConstants: Reference<LayoutConstants>) {
        self.layoutConstants = layoutConstants
        super.init(frame: .zero)
        
        insetsLayoutMarginsFromSafeArea = false
        preservesSuperviewLayoutMargins = true
        
        leftKeys = []
        middleKeys = []
        rightKeys = []
    }

    required init?(coder: NSCoder) {
        fatalError("NSCoder is not supported")
    }
    
    func setupRow(keyboardState: KeyboardState, _ keyCapGroups: [[KeyCap]], rowId: Int) {
        assert(keyCapGroups.count == 1 || keyCapGroups.count == 3)
        
        self.rowId = rowId
        
        let leftKeyCaps, middleKeyCaps, rightKepCaps: [KeyCap]
        if keyCapGroups.count == 1 {
            leftKeyCaps = []
            middleKeyCaps = keyCapGroups[0]
            rightKepCaps = []
        } else {
            leftKeyCaps = keyCapGroups[0]
            middleKeyCaps = keyCapGroups[1]
            rightKepCaps = keyCapGroups[2]
        }
        
        prepareKeys(keyCaps: leftKeyCaps, keyboardState: keyboardState, keys: &leftKeys)
        prepareKeys(keyCaps: middleKeyCaps, keyboardState: keyboardState, keys: &middleKeys)
        prepareKeys(keyCaps: rightKepCaps, keyboardState: keyboardState, keys: &rightKeys, reuseKeyFromLeft: false)
        
        let layoutConstants = layoutConstants.ref
        if layoutConstants.idiom.isPadFull {
            leftKeys.forEach { $0.contentHorizontalAlignment = $0.keyCap.keyCapType == .input ? .center : .left }
            middleKeys.forEach { $0.contentHorizontalAlignment = .center }
            rightKeys.forEach { $0.contentHorizontalAlignment = $0.keyCap.keyCapType == .input ? .center : .right }
        } else {
            leftKeys.forEach { $0.contentHorizontalAlignment = .center }
            middleKeys.forEach { $0.contentHorizontalAlignment = .center }
            rightKeys.forEach { $0.contentHorizontalAlignment = .center }
        }
    }
    
    private func prepareKeys(keyCaps: [KeyCap]?, keyboardState: KeyboardState, keys: inout [KeyView], reuseKeyFromLeft: Bool = true) {
        guard let keyCaps = keyCaps else { return }
        
        // Reuse keys. Only create/remove keys if necessary.
        
        // Create new keys if necessary.
        while keyCaps.count > keys.count {
            let newKey = KeyView(layoutConstants: layoutConstants)
            addSubview(newKey)
            if reuseKeyFromLeft {
                keys.append(newKey)
            } else {
                keys.insert(newKey, at: 0)
            }
        }
        
        // Remove extra keys to free memory.
        while keyCaps.count < keys.count {
            guard keys.count > 0 else { break }
            if reuseKeyFromLeft {
                keys.removeLast().removeFromSuperview()
            } else {
                keys.removeFirst().removeFromSuperview()
            }
        }
        
        let isPadTopRow = rowId == 0 && layoutConstants.ref.idiom == .pad(.padFull5Rows)
        for i in 0..<keyCaps.count {
            var keyCap = keyCaps[i]
            
            switch keyCap {
                case .nextKeyboard: keyCap = needsInputModeSwitchKey ? KeyCap.nextKeyboard : KeyCap.keyboardType(.emojis)
                default: ()
            }
            keys[i].setKeyCap(keyCap, keyboardState: keyboardState, isPadTopRowButton: isPadTopRow)
        }
    }
}

// Layout related coded.
extension KeyRowView {
    override func layoutSubviews() {
        let layoutIdiom = layoutConstants.ref.idiom
        let layoutConstants = self.layoutConstants.ref

        let allKeys = leftKeys + middleKeys + rightKeys
        
        let allFrames = layoutIdiom.keyboardViewLayout.layoutKeyViews(keyRowView: self, leftKeys: leftKeys, middleKeys: middleKeys, rightKeys: rightKeys, layoutConstants: layoutConstants)
        
        // Then, expand the keys to fill the void between keys.
        // In the stock keyboard, if the user tap between two keys, the event is sent to the nearest key.
        expandKeysToFillGap(allKeys, allFrames)
    }
    
    private func expandKeysToFillGap(_ allKeys: [KeyView], _ allFrames: [CGRect]) {
        guard !bounds.isEmpty else { return }

        var startX = bounds.minX
        let allKeyCount = allKeys.count
        for (index, key) in allKeys.enumerated() {
            let isLastKey = index == allKeyCount - 1
            let thisKeyFrame = allFrames[index]
            
            if rowId == 0 {
                key.heightClearance = frame.minY + 8
            }
            key.frame = thisKeyFrame
            let midXBetweenThisAndNextKey = isLastKey ? bounds.maxX : (thisKeyFrame.maxX + allFrames[index + 1].minX) / 2
            let hitTestFrame = CGRect(x: startX, y: 0, width: midXBetweenThisAndNextKey - startX, height: bounds.height)
            key.hitTestFrame = hitTestFrame
            
            startX = midXBetweenThisAndNextKey
        }
    }
}

extension KeyRowView {
    // Forward all touch events to the superview.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        superview?.touchesCancelled(touches, with: event)
    }
}
