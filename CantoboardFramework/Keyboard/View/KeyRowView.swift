//
//  StockboardKeyRow.swift
//  KeyboardKit
//
//  Created by Alex Man on 1/16/21.
//

import Foundation
import UIKit

class KeyRowView: UIView {
    enum RowLayoutMode {
        case topRow, normalRow, shiftRow, bottomRow
    }
    
    private var leftKeys, middleKeys, rightKeys: [KeyView]!
    private var keyboardType: KeyboardType = .none
    var rowLayoutMode: RowLayoutMode = .normalRow
    var needsInputModeSwitchKey = false
    
    var isEnabled: Bool = true {
        didSet {
            leftKeys.forEach { $0.isKeyEnabled = isEnabled }
            middleKeys.forEach { $0.isKeyEnabled = isEnabled }
            rightKeys.forEach { $0.isKeyEnabled = isEnabled }
        }
    }
    
    init() {
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
    
    func setupRow(keyboardType: KeyboardType, _ keyCapGroups: [[KeyCap]]) {
        assert(keyCapGroups.count == 1 || keyCapGroups.count == 3)
        
        self.keyboardType = keyboardType
        
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
        
        prepareKeys(keyCaps: leftKeyCaps, keys: &leftKeys)
        prepareKeys(keyCaps: middleKeyCaps, keys: &middleKeys)
        prepareKeys(keyCaps: rightKepCaps, keys: &rightKeys, reuseKeyFromLeft: false)
    }
    
    private func prepareKeys(keyCaps: [KeyCap]?, keys: inout [KeyView], reuseKeyFromLeft: Bool = true) {
        guard let keyCaps = keyCaps else { return }
        
        // Reuse keys. Only create/remove keys if necessary.
        
        // Create new keys if necessary.
        while keyCaps.count > keys.count {
            let newKey = KeyView()
            addSubview(newKey)
            if reuseKeyFromLeft {
                keys.append(newKey)
            } else {
                keys.insert(newKey, at: 0)
            }
        }
        
        // Remove extra keys to free memory.
        while keyCaps.count < keys.count {
            guard let lastKey = keys.last else { break }
            lastKey.removeFromSuperview()
            if reuseKeyFromLeft {
                keys.removeLast()
            } else {
                keys.removeFirst()
            }
        }
        
        for i in 0..<keyCaps.count {
            var keyCap = keyCaps[i]
            
            switch keyCap {
                case .nextKeyboard: keyCap = needsInputModeSwitchKey ? KeyCap.nextKeyboard : KeyCap.keyboardType(.emojis)
                default: ()
            }
            
            keys[i].keyCap = keyCap
        }
    }
}

// Layout related coded.
extension KeyRowView {
    private enum GroupLayoutDirection {
        case left, middle, right
    }
    
    override func layoutSubviews() {
        let layoutConstants = LayoutConstants.forMainScreen
        
        // First, put the keys to where they should be.
        let leftKeyFrames = layoutKeys(leftKeys, direction: .left, layoutConstants: layoutConstants)
        let middleKeyFrames = layoutKeys(middleKeys, direction: .middle, layoutConstants: layoutConstants)
        let rightKeyFrames = layoutKeys(rightKeys, direction: .right, layoutConstants: layoutConstants)
        
        let allKeys = leftKeys + middleKeys + rightKeys
        var allFrames = leftKeyFrames + middleKeyFrames + rightKeyFrames
        
        // Special case, widen the space key to fill the empty space.
        if rowLayoutMode == .bottomRow && middleKeys.count == 1 && middleKeys.first!.keyCap == .space {
            let thisKeyFrame = allFrames[leftKeyFrames.count]
            let spaceStartX = allFrames[leftKeyFrames.count - 1].maxX + layoutConstants.buttonGap
            let spaceEndX = allFrames[leftKeyFrames.count + middleKeyFrames.count].minX - layoutConstants.buttonGap
            allFrames[leftKeyFrames.count] = CGRect(x: spaceStartX, y: thisKeyFrame.minY, width: spaceEndX - spaceStartX, height: thisKeyFrame.maxY - thisKeyFrame.minY)
        }
        
        // Then, expand the keys to fill the void between keys.
        // In the stock keyboard, if the user tap between two keys, the event is sent to the nearest key.
        expandKeysToFillGap(allKeys, allFrames)
    }
    
    private func layoutKeys(_ keys: [KeyView], direction: GroupLayoutDirection, layoutConstants: LayoutConstants) -> [CGRect] {
        var x: CGFloat
        switch direction {
        case .left:
            x = directionalLayoutMargins.leading
        case .middle:
            let middleKeysCount = CGFloat(keys.count)
            let middleKeysWidth = keys.reduce(0, { $0 + getKeyWidth($1, layoutConstants) }) + (middleKeysCount - 1) * layoutConstants.buttonGap
            x = (bounds.width - middleKeysWidth) / 2
        case .right:
            let rightKeysCount = CGFloat(keys.count)
            let rightKeysWidth = keys.reduce(0, { $0 + getKeyWidth($1, layoutConstants) }) + (rightKeysCount - 1) * layoutConstants.buttonGap
            x = bounds.maxX - directionalLayoutMargins.trailing - rightKeysWidth
        }
        
        let frame: [CGRect] = keys.map { key in
            let keyWidth = getKeyWidth(key, layoutConstants)
            let rect = CGRect(x: x, y: layoutMargins.top, width: keyWidth, height: layoutConstants.keyHeight)
            x += keyWidth + layoutConstants.buttonGap
            
            return rect
        }
        return frame
    }
    
    private func expandKeysToFillGap(_ allKeys: [KeyView], _ allFrames: [CGRect]) {
        var startX = bounds.minX
        let allKeyCount = allKeys.count
        for (index, key) in allKeys.enumerated() {
            let isLastKey = index == allKeyCount - 1
            let thisKeyFrame = allFrames[index]
            
            if rowLayoutMode == .topRow {
                key.heightClearance = frame.minY + 8
            }
            key.frame = thisKeyFrame
            let midXBetweenThisAndNextKey = isLastKey ? bounds.maxX : (thisKeyFrame.maxX + allFrames[index + 1].minX) / 2
            let hitTestFrame = CGRect(x: startX, y: 0, width: midXBetweenThisAndNextKey - startX, height: bounds.height)
            key.hitTestFrame = hitTestFrame
            
            startX = midXBetweenThisAndNextKey
        }
    }
    
    private func getKeyWidth(_ key: KeyView, _ layoutConstants: LayoutConstants) -> CGFloat {
        if case .character(_) = key.keyCap, rowLayoutMode == .shiftRow && (keyboardType == .symbolic || keyboardType == .numeric) {
            return layoutConstants.widerSymbolButtonWidth
        } else {
            return key.keyCap.buttonWidth(layoutConstants)
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
