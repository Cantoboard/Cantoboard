//
//  CandidateCollectionView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/25/21.
//

import Foundation
import UIKit

protocol CandidateCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didLongPressItemAt indexPath: IndexPath)
}

// This is the UICollectionView inside CandidatePaneView.
class CandidateCollectionView: UICollectionView {
    private let c = InstanceCounter<CandidateCollectionView>()
    
    private static let longPressDelay: Double = 1
    private static let longPressMovement: CGFloat = 10
    
    var scrollOnLayoutSubviews: (() -> Bool)?
    
    private var longPressTimer: Timer?
    private weak var cancelTouch: UITouch?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let candidatePaneView = superview as? CandidatePaneView {
            candidatePaneView.canExpand = contentSize.width > bounds.width
        }
        
        if scrollOnLayoutSubviews?() ?? false {
            scrollOnLayoutSubviews = nil
        }
    }
    
    @objc private func onLongPress(longPressTouch: UITouch, longPressBeginPoint: CGPoint) {
        if let d = delegate as? CandidateCollectionViewDelegate,
           longPressBeginPoint.distanceTo(longPressTouch.location(in: self)).isLessThanOrEqualTo(Self.longPressMovement),
           let indexPath = indexPathForItem(at: longPressBeginPoint) {
            d.collectionView(self, didLongPressItemAt: indexPath)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        longPressTimer?.invalidate()
        
        guard let longPressTouch = touches.first else { return }
        let longPressBeginPoint = longPressTouch.location(in: self)
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: Self.longPressDelay, repeats: false) { [weak self] timer in
            guard let self = self, self.longPressTimer == timer else { return }
            self.onLongPress(longPressTouch: longPressTouch, longPressBeginPoint: longPressBeginPoint)
            self.longPressTimer = nil
            self.cancelTouch = longPressTouch
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        var touches = touches
        if let cancelTouch = cancelTouch {
            touches.remove(cancelTouch)
        }
        super.touchesEnded(touches, with: event)
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        longPressTimer?.invalidate()
        longPressTimer = nil
    }
    
    func reloadCandidates() {
        reloadData()
        
        guard numberOfSections > 1 else { return }
        
        let visibleCellCounts = min(indexPathsForVisibleItems.count, dataSource?.collectionView(self, numberOfItemsInSection: 1) ?? 0)
        // For some reason, sometimes willDisplayCell isn't called for the first few visible cells.
        // Manually refreshing them to workaround the bug.
        reloadItems(at: (0..<visibleCellCounts).map({ [1, $0] }))
    }
}
