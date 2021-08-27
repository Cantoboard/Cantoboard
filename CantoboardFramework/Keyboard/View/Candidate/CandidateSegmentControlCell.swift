//
//  CandidateSegmentControlCell.swift
//  CantoboardFramework
//
//  Created by Alex Man on 8/25/21.
//

import Foundation
import UIKit

// The cell that contains the segment control to change between group by mode.
class CandidateSegmentControlCell: UICollectionViewCell {
    static var reuseId: String = "CandidateGroupBySegmentControl"
    private static let inset = UIEdgeInsets(top: 6, left: 8, bottom: 8, right: 12)
    
    weak var segmentedControl: UISegmentedControl?
    var groupByModes: [GroupByMode]?
    var onSelectionChanged: ((_ groupByMode: GroupByMode) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    func setup(groupByModes: [GroupByMode], selectedGroupByMode: GroupByMode, onSelectionChanged: ((_ groupByMode: GroupByMode) -> Void)?) {
        self.onSelectionChanged = onSelectionChanged
        
        if segmentedControl == nil {
            let segmentControl = UISegmentedControl()
            addSubview(segmentControl)
            segmentControl.addTarget(self, action: #selector(onSegmentControlChange), for: .valueChanged)
            self.segmentedControl = segmentControl
        }
        
        guard let segmentControl = segmentedControl, segmentControl.numberOfSegments != groupByModes.count else { return }
        
        let font: UIFont = .preferredFont(forTextStyle: .subheadline)
        segmentControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        
        UIView.performWithoutAnimation {
            segmentControl.removeAllSegments()
            self.groupByModes = groupByModes
            for i in 0..<groupByModes.count {
                segmentControl.insertSegment(withTitle: groupByModes[i].title, at: i, animated: false)
                if groupByModes[i] == selectedGroupByMode {
                    segmentControl.selectedSegmentIndex = i
                }
            }
        }
    }
    
    func update(selectedGroupByMode: GroupByMode) {
        guard let groupByModes = groupByModes else { return }
        for i in 0..<groupByModes.count {
            if groupByModes[i] == selectedGroupByMode {
                UIView.performWithoutAnimation {
                    segmentedControl?.selectedSegmentIndex = i
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        layout(layoutAttributes.bounds)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout(bounds)
    }
    
    private func layout(_ bounds: CGRect) {
        segmentedControl?.frame = bounds.inset(by: Self.inset)
    }
    
    @objc private func onSegmentControlChange() {
        guard let segmentControl = segmentedControl,
              let selectedGroupByMode = groupByModes?[safe: segmentControl.selectedSegmentIndex]
              else { return }
        
        onSelectionChanged?(selectedGroupByMode)
    }
}
