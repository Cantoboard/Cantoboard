//
//  CandidatePaneView.swift
//  UIKitPlayground
//
//  Created by Alex Man on 1/5/21.
//  Copyright © 2021 Alex Man. All rights reserved.
//

import Foundation
import UIKit

class CandidateSource {
    let candidates: NSArray
    let requestMoreCandidate: () -> Bool
    
    init(candidates: NSArray, requestMoreCandidate: @escaping () -> Bool) {
        self.candidates = candidates
        self.requestMoreCandidate = requestMoreCandidate
    }
}

class CandidateCell: UICollectionViewCell {
    static var ReuseId: String = "CandidateCell"
    static let FontSize = CGFloat(22)
    static let Font = UIFont.systemFont(ofSize: CandidateCell.FontSize)
    static let UnitCharSize: CGSize = "＠".size(withAttributes: [NSAttributedString.Key.font : Font])
    static let Margin = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

    weak var label: UILabel?

    override init(frame: CGRect) {
        super.init(frame: .zero)
    }
    
    func initLabel(_ text: String) {
        if label == nil {
            let label = UILabel()
            label.textAlignment = .center
            label.baselineAdjustment = .alignBaselines
            label.isUserInteractionEnabled = false
            label.font = CandidateCell.Font

            self.contentView.addSubview(label)
            self.label = label
        }
        
        label?.frame = bounds
        label?.text = text
    }
    
    func deinitLabel() {
        label?.text = nil
        // label?.removeFromSuperview()
        // label = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        self.label?.frame = layoutAttributes.bounds
    }
}

class CandidateCollectionView: UICollectionView {
    var scrollOnLayoutSubviews: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollOnLayoutSubviews?()
        scrollOnLayoutSubviews = nil
    }
}

protocol CandidatePaneViewDelegate: NSObject {
    func candidatePaneViewExpanded()
    func candidatePaneViewCollapsed()
    func candidatePaneViewCandidateSelected(_ choice: Int)
    func candidatePaneCandidateLoaded()
}

class CandidatePaneView: UIControl {
    enum Mode {
        case row
        case table
    }
    
    let RowPadding = CGFloat(0)

    // TODO move this to a centralized place.
    private let PaneCollapseButtonImage = UIImage(systemName: "chevron.up")
    private let PaneExpandButtonImage = UIImage(systemName: "chevron.down")
    
    weak var collectionView: CandidateCollectionView!
    weak var expandButton: UIButton!
    weak var delegate: CandidatePaneViewDelegate?

    var rowStyleHeightConstraint: NSLayoutConstraint!
    var tableStyleBottomConstraint: NSLayoutConstraint?
    
    private(set) var mode: Mode = .row
    
    var candidateSource: CandidateSource? {
        didSet {
            if let candidateSource = self.candidateSource {
                NSLog("CandidateSource changed. Refreshing collection view.")
                _ = candidateSource.requestMoreCandidate()
            }

            UIView.performWithoutAnimation {
                collectionView.scrollOnLayoutSubviews = {
                    self.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
                }
                collectionView.reloadData()
            }
            
            isHidden = candidateSource?.candidates.count ?? 0 == 0
            if isHidden { changeMode(.row) }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        // self.backgroundColor = .gray
        isHidden = true
        
        loadCollectionView()
        loadExpandButton()
        
        rowStyleHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: getRowHeight() + RowPadding)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: expandButton.leadingAnchor),
            expandButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            expandButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            expandButton.heightAnchor.constraint(equalToConstant: getRowHeight() + RowPadding),
            expandButton.widthAnchor.constraint(equalToConstant: getRowHeight() + RowPadding),
            self.heightAnchor.constraint(equalToConstant: getRowHeight() + RowPadding),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadExpandButton() {
        let expandButton = UIButton()
        expandButton.translatesAutoresizingMaskIntoConstraints = false
        expandButton.layer.contentsFormat = .gray8Uint
        //expandButton.layer.cornerRadius = 5
        expandButton.setImage(PaneExpandButtonImage, for: .normal)
        expandButton.setTitleColor(.label, for: .normal)
        expandButton.tintColor = .label
        // expandButton.highlightedBackgroundColor = self.HIGHLIGHTED_COLOR
        expandButton.addTarget(self, action: #selector(self.expandButtonClick), for: .touchUpInside)
        
        addSubview(expandButton)
        
        self.expandButton = expandButton
    }
    
    private func loadCollectionView() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.headerReferenceSize = CGSize(width: 0, height: RowPadding / CGFloat(2))

        let collectionView = CandidateCollectionView(frame :.zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.ReuseId)
        collectionView.allowsSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false

        self.addSubview(collectionView)

        self.collectionView = collectionView
    }
    
    override func didMoveToSuperview() {
        self.needsUpdateConstraints()
        self.updateConstraints() // TODO revisit
    }
    
    private func getRowHeight() -> CGFloat {
        return CandidateCell.UnitCharSize.height + CandidateCell.Margin.top + CandidateCell.Margin.bottom
    }
    
    @objc private func expandButtonClick() {
        self.changeMode(mode == .row ? .table : .row)
    }
    
    override func updateConstraints() {
        if self.tableStyleBottomConstraint == nil {
            self.tableStyleBottomConstraint = self.collectionView.bottomAnchor.constraint(equalTo: self.superview!.bottomAnchor)
        }
                
        let isRowMode = self.mode == .row

        self.rowStyleHeightConstraint.isActive = isRowMode
        self.tableStyleBottomConstraint!.isActive = !isRowMode
        
        self.collectionView.alwaysBounceHorizontal = isRowMode
        self.collectionView.alwaysBounceVertical = !isRowMode
        
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = isRowMode ? .horizontal : .vertical
        flowLayout.minimumLineSpacing = RowPadding
        
        super.updateConstraints()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || window == nil { return nil }
        if mode == .row {
            return super.hitTest(point, with: event)
        }
        
        let result = collectionView.hitTest(self.convert(point, to: collectionView), with: event)
        if result != nil {
            return result
        } else {
            return super.hitTest(point, with: event)
        }
    }
}

extension CandidatePaneView {
    private func changeMode(_ newMode: Mode) {
        guard mode != newMode else { return }
        
        NSLog("CandidatePaneView.changeMode start")
        let firstVisibleIndexPath = getFirstVisibleIndexPath()
        
        let expandButtonImage = newMode == .row ? PaneExpandButtonImage : PaneCollapseButtonImage
        self.expandButton.setImage(expandButtonImage, for: .normal)

        self.mode = newMode
        if let scrollToIndexPath = firstVisibleIndexPath {
            let scrollToIndexPathDirection: UICollectionView.ScrollPosition = newMode == .row ? .left : .top
            
            self.collectionView.scrollOnLayoutSubviews = {
                guard let collectionView = self.collectionView else { return }
                collectionView.scrollToItem(at: scrollToIndexPath, at: scrollToIndexPathDirection, animated: false)
                
                collectionView.showsVerticalScrollIndicator = scrollToIndexPathDirection == .top
            }
        }
        
        self.setNeedsUpdateConstraints()
        
        if newMode == .row {
            delegate?.candidatePaneViewCollapsed()
        } else {
            delegate?.candidatePaneViewExpanded()
        }
        NSLog("CandidatePaneView.changeMode end")
    }
    
    func getFirstVisibleIndexPath() -> IndexPath? {
        let unitCharSize = CandidateCell.UnitCharSize
        let firstAttempt = self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: unitCharSize.width / 2, y: unitCharSize.height / 2), to: self.collectionView))
        if firstAttempt != nil { return firstAttempt }
        return self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: unitCharSize.width / 2, y: unitCharSize.height / 2 + 2 * RowPadding), to: self.collectionView))
    }
}

extension CandidatePaneView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return candidateSource?.candidates.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.ReuseId, for: indexPath) as! CandidateCell
        
        let candidateCount = self.collectionView.numberOfItems(inSection: 0)
        if indexPath.row == candidateCount - 1 {
            DispatchQueue.main.async { self.loadMoreCandidates() }
        }
        
        return cell
    }
    
    private func loadMoreCandidates() {
        UIView.performWithoutAnimation {
            guard let candidateSource = self.candidateSource else { return }
            
            guard candidateSource.requestMoreCandidate() else { return }
            
            let newIndiceStart = self.collectionView.numberOfItems(inSection: 0)
            let newIndiceEnd =  candidateSource.candidates.count
            // print("Inserting new candidates: ", newIndiceStart, newIndiceEnd)
            self.collectionView.insertItems(at: (newIndiceStart..<newIndiceEnd).map { IndexPath(row: $0, section: 0) })
            delegate?.candidatePaneCandidateLoaded()
        }
    }
}

extension CandidatePaneView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return computeCellSize(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if mode == .row {
            return 0
        } else {
            return RowPadding
        }
    }
    
    private func computeCellSize(_ indexPath: IndexPath) -> CGSize {
        guard let candidates = self.candidateSource?.candidates else { return CGSize(width: 0, height: 0) }
        guard indexPath.row < candidates.count else {
            NSLog("Invalid IndexPath %@. Candidate does not exist.", indexPath.description)
            return CGSize(width: 0, height: 0)
        }
        let text = candidates[indexPath.row] as? String ?? "⚠"
        return computeTextSize(text)
    }
    
    /*
    // Fixed width mode.
    private func computeTextSize(_ text: String) -> CGSize {
        let textLen = CGFloat(text.count)
        let result = CGSize(
            width: UNIT_CHAR_SIZE.height * textLen + CANDIDATE_MARGIN.left + CANDIDATE_MARGIN.right,
            height: UNIT_CHAR_SIZE.height + CANDIDATE_MARGIN.top + CANDIDATE_MARGIN.bottom)
        // print(text, ratio, result.width, result.height)
        return result
    }*/
    
    // Font based.
    private func computeTextSize(_ text: String) -> CGSize {
        let fontAttributes = [NSAttributedString.Key.font:  CandidateCell.Font]
        var size = (text as NSString).size(withAttributes: fontAttributes)
        if size.width < CandidateCell.UnitCharSize.width { size.width = CandidateCell.UnitCharSize.width }
        return CGSize(width: size.width + CandidateCell.Margin.left + CandidateCell.Margin.right, height: size.height + CandidateCell.Margin.top + CandidateCell.Margin.bottom)
    }
}

extension CandidatePaneView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.candidatePaneViewCandidateSelected(indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let candidates = self.candidateSource?.candidates,
           let cell = cell as? CandidateCell {
            cell.initLabel(candidates[indexPath.row] as! String)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CandidateCell {
            cell.deinitLabel()
        }
    }
}
