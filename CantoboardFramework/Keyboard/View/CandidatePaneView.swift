//
//  CandidatePaneView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/5/21.
//  Copyright © 2021 Alex Man. All rights reserved.
//

import Foundation
import UIKit

class CandidatePaneView: UIControl {
    private static let hapticsGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    enum Mode {
        case row, table
    }
    
    enum FilterMode {
        case lang, shape
    }
    
    let rowPadding = CGFloat(0)
    
    weak var candidateOrganizer: CandidateOrganizer? {
        didSet {
            candidateOrganizer?.onMoreCandidatesLoaded = { [weak self] candidateOrganizer in
                guard let self = self else { return }
                
                let newIndiceStart = self.collectionView.numberOfItems(inSection: 0)
                let candidates = candidateOrganizer.getCandidates(section: 0)
                let newIndiceEnd = candidates.count
                
                NSLog("Inserting new candidates: \(newIndiceStart)..<\(newIndiceEnd)")
                
                UIView.performWithoutAnimation {
                    self.collectionView.insertItems(at: (newIndiceStart..<newIndiceEnd).map { IndexPath(row: $0, section: 0) })
                }
                self.delegate?.candidatePaneCandidateLoaded()
            }
            
            candidateOrganizer?.onReloadCandidates = { [weak self] candidateOrganizer in
                guard let self = self else { return }
                
                NSLog("Reloading candidates.")
                
                UIView.performWithoutAnimation {
                    self.collectionView.scrollOnLayoutSubviews = {
                        self.collectionView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
                    }
                    self.collectionView.reloadData()
                }
                if self.candidateOrganizer?.candidateSource == nil { self.changeMode(.row) }
            }
        }
    }
    weak var collectionView: CandidateCollectionView!
    weak var buttonStackView: UIStackView!
    weak var expandButton, filterButton, backspaceButton: UIButton!
    weak var delegate: CandidatePaneViewDelegate?
    
    var rowStyleHeightConstraint: NSLayoutConstraint!
    var tableStyleBottomConstraint: NSLayoutConstraint?
    
    private(set) var mode: Mode = .row
    var filterMode: FilterMode = .lang {
        didSet {
            setupButtons()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        initCollectionView()
        initStackView()
        
        rowStyleHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: getRowHeight() + rowPadding)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: getRowHeight() + rowPadding),
            
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),
            
            buttonStackView.topAnchor.constraint(equalTo: topAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonStackView.widthAnchor.constraint(equalToConstant: getRowHeight() + rowPadding),
            // buttonStackView.heightAnchor.constraint(equalTo: collectionView.heightAnchor),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initStackView() {
        let buttonStackView = UIStackView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.axis = .vertical
        buttonStackView.alignment = .top
        buttonStackView.distribution = .fillProportionally
        addSubview(buttonStackView)
        self.buttonStackView = buttonStackView
        
        expandButton = createAndAddButton()
        expandButton.addTarget(self, action: #selector(self.expandButtonClick), for: .touchUpInside)

        filterButton = createAndAddButtonWithBackground()
        filterButton.addTarget(self, action: #selector(self.filterButtonClick), for: .touchUpInside)
        
        backspaceButton = createAndAddButton()
        backspaceButton.addTarget(self, action: #selector(self.backspaceButtonClick), for: .touchUpInside)
    }
    
    private func createAndAddButton() -> UIButton {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.contentsFormat = .gray8Uint
        //button.layer.cornerRadius = 5
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label
        // button.highlightedBackgroundColor = self.HIGHLIGHTED_COLOR
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: getRowHeight() + rowPadding),
            button.heightAnchor.constraint(equalToConstant: getRowHeight() + rowPadding),
        ])
        
        buttonStackView.addArrangedSubview(button)
        return button
    }
    
    private func createAndAddButtonWithBackground() -> UIButton {
        let button = createAndAddButton()
        
        let statusSquareBg = CALayer()
        statusSquareBg.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: getRowHeight() + rowPadding, height: getRowHeight() + rowPadding)).insetBy(dx: 5, dy: 5)
        statusSquareBg.backgroundColor = CGColor(gray: 0.5, alpha: 0.5)
        statusSquareBg.cornerRadius = 3
        statusSquareBg.masksToBounds = true
        button.layer.addSublayer(statusSquareBg)
        
        return button
    }
    
    private func setupButtons() {
        guard let candidateOrganizer = candidateOrganizer else { return }
        
        let expandButtonImage = mode == .row ? ButtonImage.paneExpandButtonImage : ButtonImage.paneCollapseButtonImage
        expandButton.setImage(expandButtonImage, for: .normal)
        
        var title: String?
        if filterMode == .lang {
            switch candidateOrganizer.inputMode {
            case .mixed: title = "雙"
            case .chinese: title = "中"
            case .english: title = "英"
            }
        } else {
            if let symbolShape = delegate?.symbolShape {
                switch symbolShape {
                case .full: title = "全"
                case .half: title = "半"
                default: title = nil
                }
            }
        }
        
        filterButton.setTitle(title, for: .normal)
        
        backspaceButton.setImage(ButtonImage.backspace, for: .normal)
        
        if mode == .table {
            expandButton.isHidden = false
            filterButton.isHidden = false || title == nil
            backspaceButton.isHidden = false
        } else {
            let cannotExpand = collectionView.contentSize.width <= 1 || collectionView.contentSize.width < collectionView.bounds.width
            
            expandButton.isHidden = cannotExpand
            filterButton.isHidden = !cannotExpand || title == nil
            backspaceButton.isHidden = true
        }
    }
    
    private func initCollectionView() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.headerReferenceSize = CGSize(width: 0, height: rowPadding / CGFloat(2))

        let collectionView = CandidateCollectionView(frame :.zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.ReuseId)
        collectionView.allowsSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.didLayoutSubviews = { [weak self] _ in
            self?.setupButtons()
        }
        
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
        changeMode(mode == .row ? .table : .row)
    }
    
    @objc private func filterButtonClick() {
        Self.hapticsGenerator.impactOccurred(intensity: 1)
        AudioFeedbackProvider.play(keyboardAction: .none)
        
        if filterMode == .lang {
            guard let candidateOrganizer = candidateOrganizer else { return }
            
            var nextFilterMode: InputMode
            switch candidateOrganizer.inputMode {
            case .mixed: nextFilterMode = .english
            case .chinese: nextFilterMode = .english
            case .english: nextFilterMode = Settings.cached.isMixedModeEnabled ? .mixed : .chinese
            }
            
            candidateOrganizer.inputMode = nextFilterMode
            delegate?.handleKey(.refreshMarkedText)
        } else {
            guard let symbolShape = delegate?.symbolShape else { return }
            switch symbolShape {
            case .full: delegate?.symbolShapeOverride = .half
            case .half: delegate?.symbolShapeOverride = .full
            default: ()
            }
            setupButtons()
        }
    }
    
    @objc private func backspaceButtonClick() {
        delegate?.handleKey(.backspace)
    }
    
    override func updateConstraints() {
        if tableStyleBottomConstraint == nil {
            tableStyleBottomConstraint = self.collectionView.bottomAnchor.constraint(equalTo: self.superview!.bottomAnchor)
        }
        
        let isRowMode = self.mode == .row
        
        rowStyleHeightConstraint.isActive = isRowMode
        tableStyleBottomConstraint!.isActive = !isRowMode
        
        collectionView.alwaysBounceHorizontal = isRowMode
        collectionView.alwaysBounceVertical = !isRowMode
        
        let flowLayout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = isRowMode ? .horizontal : .vertical
        flowLayout.minimumLineSpacing = rowPadding
        
        super.updateConstraints()
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || window == nil { return nil }
        if mode == .row {
            return super.hitTest(point, with: event)
        }
        
        for subview in subviews {
            let result = subview.hitTest(self.convert(point, to: subview), with: event)
            if result != nil {
                return result
            }
        }
        return super.hitTest(point, with: event)
    }
}

extension CandidatePaneView {
    private func changeMode(_ newMode: Mode) {
        guard mode != newMode else { return }
        
        // NSLog("CandidatePaneView.changeMode start")
        let firstVisibleIndexPath = getFirstVisibleIndexPath()
                
        mode = newMode
        setupButtons()
        
        if let scrollToIndexPath = firstVisibleIndexPath {
            let scrollToIndexPathDirection: UICollectionView.ScrollPosition = newMode == .row ? .left : .top
            
            collectionView.scrollOnLayoutSubviews = {
                guard let collectionView = self.collectionView else { return }
                collectionView.scrollToItem(at: scrollToIndexPath, at: scrollToIndexPathDirection, animated: false)
                
                collectionView.showsVerticalScrollIndicator = scrollToIndexPathDirection == .top
            }
        }
        
        setNeedsUpdateConstraints()
        
        if newMode == .row {
            delegate?.candidatePaneViewCollapsed()
        } else {
            delegate?.candidatePaneViewExpanded()
        }
        // NSLog("CandidatePaneView.changeMode end")
    }
    
    func getFirstVisibleIndexPath() -> IndexPath? {
        let unitCharSize = CandidateCell.UnitCharSize
        let firstAttempt = self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: unitCharSize.width / 2, y: unitCharSize.height / 2), to: self.collectionView))
        if firstAttempt != nil { return firstAttempt }
        return self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: unitCharSize.width / 2, y: unitCharSize.height / 2 + 2 * rowPadding), to: self.collectionView))
    }
}

extension CandidatePaneView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return candidateOrganizer?.getCandidates(section: section).count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.ReuseId, for: indexPath) as! CandidateCell
        
        let candidateCount = self.collectionView.numberOfItems(inSection: 0)
        if indexPath.section == 0 && indexPath.row == candidateCount - 1 {
            DispatchQueue.main.async { [weak self] in
                self?.candidateOrganizer?.requestMoreCandidates(section: 0)
            }
        }
        
        return cell
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
            return rowPadding
        }
    }
    
    private func computeCellSize(_ indexPath: IndexPath) -> CGSize {
        guard let candidateOrganizer = candidateOrganizer else { return CGSize(width: 0, height: 0) }
        let candidates = candidateOrganizer.getCandidates(section: indexPath.section)
        guard indexPath.row < candidates.count else {
            NSLog("Invalid IndexPath %@. Candidate does not exist.", indexPath.description)
            return CGSize(width: 0, height: 0)
        }
        var text = candidates[indexPath.row] as? String ?? "⚠"
        if text.count == 1 { text += " " } // Pad single char candidate.
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
        guard let candidateOrganizer = candidateOrganizer,
              let index = candidateOrganizer.getCandidateIndex(indexPath: indexPath) else { return }
        delegate?.candidatePaneViewCandidateSelected(index)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let candidateOrganizer = candidateOrganizer,
              let candidate = candidateOrganizer.getCandidate(indexPath: indexPath),
              let cell = cell as? CandidateCell else { return }
        cell.initLabel(candidate)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CandidateCell {
            cell.deinitLabel()
        }
    }
}
