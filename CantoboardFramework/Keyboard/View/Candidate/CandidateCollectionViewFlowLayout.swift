//
//  CandidateCollectionViewFlowLayout.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

class CandidateCollectionViewFlowLayout: UICollectionViewFlowLayout {
    private weak var candidatePaneView: CandidatePaneView?
    
    init(candidatePaneView: CandidatePaneView) {
        self.candidatePaneView = candidatePaneView
        super.init()
        sectionHeadersPinToVisibleBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var collectionViewContentSize: CGSize {
        var contentSize = super.collectionViewContentSize
        let segmentControlHeight = LayoutConstants.forMainScreen.autoCompleteBarHeight
        if let collectionView = collectionView,
           let candidatePaneView = candidatePaneView,
           candidatePaneView.mode == .table && candidatePaneView.groupByEnabled &&
           contentSize.height <= collectionView.bounds.height + segmentControlHeight {
            // Expand the content size to let user to scroll upward to see the segment control.
            contentSize.height = collectionView.bounds.height + segmentControlHeight
        }
        return contentSize
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let allAttributes = super.layoutAttributesForElements(in: rect) ?? []
        
        for attributes in allAttributes {
            if attributes.representedElementKind == UICollectionView.elementKindSectionHeader {
                fixHeaderPosition(attributes)
            }
        }
        
        return allAttributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
        if let attributes = attributes, elementKind == UICollectionView.elementKindSectionHeader {
            fixHeaderPosition(attributes)
        }
        return attributes
    }
    
    private func fixHeaderPosition(_ headerAttributes: UICollectionViewLayoutAttributes) {
        guard let candidatePaneView = candidatePaneView,
              let collectionView = collectionView
            else { return }
        
        let section = headerAttributes.indexPath.section
        guard section < collectionView.numberOfSections else { return }
        
        var headerSize = CGSize(width: candidatePaneView.sectionHeaderWidth, height: LayoutConstants.forMainScreen.autoCompleteBarHeight)
        let numOfItemsInSection = collectionView.numberOfItems(inSection: section)
        var origin = headerAttributes.frame.origin
        if numOfItemsInSection > 0,
           let rectOfLastItemInSection = layoutAttributesForItem(at: [section, numOfItemsInSection - 1]) {
            origin.y = min(origin.y, rectOfLastItemInSection.frame.maxY - headerSize.height)
            // Expand the header to cover the whole section vertically.
            headerSize.height = rectOfLastItemInSection.frame.maxY - origin.y
        }
        headerAttributes.frame = CGRect(origin: origin, size: headerSize)
    }
}
