//
//  CandidatePaneView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/5/21.
//  Copyright © 2021 Alex Man. All rights reserved.
//

import Foundation
import UIKit

protocol CandidatePaneViewDelegate: NSObject {
    func candidatePaneViewExpanded()
    func candidatePaneViewCollapsed()
    func candidatePaneViewCandidateSelected(_ choice: Int)
    func candidatePaneCandidateLoaded()
    func handleKey(_ action: KeyboardAction)
    var symbolShape: SymbolShape { get }
    var symbolShapeOverride: SymbolShape? { get set }
}

class StatusButton: UIButton {
    private static let statusInset: CGFloat = 4
    private weak var statusSquareBg: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let statusSquareBg = CALayer()
        let newActions = [
            "position": NSNull(),
            "bounds": NSNull(),
            "hidden": NSNull(),
        ]
        statusSquareBg.actions = newActions
        statusSquareBg.frame = frame.insetBy(dx: Self.statusInset, dy: Self.statusInset)
        statusSquareBg.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
        statusSquareBg.cornerRadius = 3
        statusSquareBg.masksToBounds = true
        layer.addSublayer(statusSquareBg)
        
        self.statusSquareBg = statusSquareBg
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel?.font = UIFont.systemFont(ofSize: LayoutConstants.forMainScreen.statusIndicatorFontSize)
        statusSquareBg?.frame = bounds.insetBy(dx: Self.statusInset, dy: Self.statusInset)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        statusSquareBg?.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
}

class CandidatePaneView: UIControl {
    private static let hapticsGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    enum Mode {
        case row, table
    }
    
    enum FilterMode {
        case lang, shape
    }
    
    let rowPadding = CGFloat(0)
    
    var reverseLookupSchemaId: RimeSchemaId? {
        didSet {
            setupButtons()
        }
    }
    
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
    weak var expandButton, inputModeButton, backspaceButton, charFormButton: UIButton!
    weak var delegate: CandidatePaneViewDelegate?
    
    private(set) var mode: Mode = .row
    var filterMode: FilterMode = .lang {
        didSet {
            // TODO dedup
            setupButtons()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        
        initCollectionView()
        initButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initButtons() {
        expandButton = createAndAddButton(isStatusIndicator: false)
        expandButton.addTarget(self, action: #selector(self.expandButtonClick), for: .touchUpInside)

        inputModeButton = createAndAddButton(isStatusIndicator: true)
        inputModeButton.addTarget(self, action: #selector(self.filterButtonClick), for: .touchUpInside)
        
        backspaceButton = createAndAddButton(isStatusIndicator: false)
        backspaceButton.addTarget(self, action: #selector(self.backspaceButtonClick), for: .touchUpInside)
        
        charFormButton = createAndAddButton(isStatusIndicator: true)
        charFormButton.addTarget(self, action: #selector(self.charFormButtonClick), for: .touchUpInside)
    }
    
    private func createAndAddButton(isStatusIndicator: Bool) -> UIButton {
        let button = isStatusIndicator ? StatusButton() : UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.contentsFormat = .gray8Uint
        //button.layer.cornerRadius = 5
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label
        // button.highlightedBackgroundColor = self.HIGHLIGHTED_COLOR
        
        addSubview(button)
        return button
    }
    
    private func setupButtons() {
        guard let candidateOrganizer = candidateOrganizer else { return }
        
        let expandButtonImage = mode == .row ? ButtonImage.paneExpandButtonImage : ButtonImage.paneCollapseButtonImage
        expandButton.setImage(expandButtonImage, for: .normal)
        
        var title: String?
        if filterMode == .lang {
            if let reverseLookupSchemaId = reverseLookupSchemaId {
                title = reverseLookupSchemaId.signChar
            } else {
                switch candidateOrganizer.inputMode {
                case .mixed: title = "雙"
                case .chinese: title = "中"
                case .english: title = "英"
                }
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
        inputModeButton.setTitle(title, for: .normal)

        backspaceButton.setImage(ButtonImage.backspace, for: .normal)
        
        var charFormText: String
        if Settings.cached.charForm == .simplified {
            charFormText = "簡"
        } else {
            charFormText = "繁"
        }
        charFormButton.setTitle(charFormText, for: .normal)
        
        if mode == .table {
            expandButton.isHidden = false
            inputModeButton.isHidden = false || title == nil
            backspaceButton.isHidden = false
            charFormButton.isHidden = false
        } else {
            let cannotExpand = collectionView.contentSize.width <= 1 || collectionView.contentSize.width < collectionView.bounds.width
            
            expandButton.isHidden = cannotExpand
            inputModeButton.isHidden = !cannotExpand || title == nil
            backspaceButton.isHidden = true
            charFormButton.isHidden = true
        }
        setNeedsLayout()
    }
    
    private func initCollectionView() {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.headerReferenceSize = CGSize(width: 0, height: rowPadding / CGFloat(2))

        let collectionView = CandidateCollectionView(frame :.zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.reuseId)
        collectionView.allowsSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.didLayoutSubviews = { [weak self] _ in
            self?.setupButtons()
        }
        
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.scrollDirection = mode == .row ? .horizontal : .vertical
        flowLayout.minimumLineSpacing = rowPadding
        
        self.addSubview(collectionView)
        self.collectionView = collectionView
    }
    
    override func didMoveToSuperview() {
        self.needsUpdateConstraints()
        self.updateConstraints() // TODO revisit
    }
    
    private var rowHeight: CGFloat {
        return LayoutConstants.forMainScreen.autoCompleteBarHeight + rowPadding
    }
    
    @objc private func expandButtonClick() {
        changeMode(mode == .row ? .table : .row)
    }
    
    @objc private func filterButtonClick() {
        guard reverseLookupSchemaId == nil else { return }
        
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
    
    @objc private func charFormButtonClick() {
        let currentCharForm = Settings.cached.charForm
        let newCharForm: CharForm = currentCharForm == .simplified ? .traditionalTW : .simplified
        delegate?.handleKey(.setCharForm(newCharForm))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview = superview else { return }
        let layoutConstants = LayoutConstants.forMainScreen
        let height = mode == .row ? layoutConstants.autoCompleteBarHeight : superview.bounds.height
        let buttonWidth = layoutConstants.autoCompleteBarHeight
        let candidateViewWidth = superview.bounds.width - buttonWidth
        
        collectionView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: candidateViewWidth, height: height))
        
        let buttons = [expandButton, inputModeButton, backspaceButton, charFormButton]
        var buttonY: CGFloat = 0
        for button in buttons {
            guard let button = button, !button.isHidden else { continue }
            button.frame = CGRect(origin: CGPoint(x: candidateViewWidth, y: buttonY), size: CGSize(width: buttonWidth, height: buttonWidth))
            buttonY += layoutConstants.autoCompleteBarHeight
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
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
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = mode == .row ? .horizontal : .vertical
            flowLayout.minimumLineSpacing = rowPadding
        }
        
        setNeedsLayout()
        
        if newMode == .row {
            delegate?.candidatePaneViewCollapsed()
        } else {
            delegate?.candidatePaneViewExpanded()
        }
        // NSLog("CandidatePaneView.changeMode end")
    }
    
    func getFirstVisibleIndexPath() -> IndexPath? {
        let candidateCharSize = LayoutConstants.forMainScreen.candidateCharSize
        let firstAttempt = self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: candidateCharSize.width / 2, y: candidateCharSize.height / 2), to: self.collectionView))
        if firstAttempt != nil { return firstAttempt }
        return self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: candidateCharSize.width / 2, y: candidateCharSize.height / 2 + 2 * rowPadding), to: self.collectionView))
    }
}

extension CandidatePaneView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return candidateOrganizer?.getCandidates(section: section).count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.reuseId, for: indexPath) as! CandidateCell
        
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
        let layoutConstant = LayoutConstants.forMainScreen
        
        guard indexPath.row < candidates.count else {
            NSLog("Invalid IndexPath %@. Candidate does not exist.", indexPath.description)
            return CGSize(width: 0, height: 0)
        }
        
        let text = candidates[safe: indexPath.row] as? String ?? "⚠"
        
        var cellWidth = text.size(withFont: UIFont.systemFont(ofSize: layoutConstant.candidateFontSize)).width
        let cellHeight = LayoutConstants.forMainScreen.autoCompleteBarHeight
        
        let showComment = candidateOrganizer.candidateSource is InputEngineCandidateSource &&
            (reverseLookupSchemaId != nil || Settings.cached.shouldShowRomanization && candidateOrganizer.inputMode != .english)
        if showComment {
            let comment = candidateOrganizer.getCandidateComment(indexPath: indexPath) ?? "⚠"
            let commentWidth = comment.size(withFont: UIFont.systemFont(ofSize: layoutConstant.candidateCommentFontSize)).width
            cellWidth = max(cellWidth, commentWidth)
        }
        
        // Min width
        cellWidth = max(cellWidth, layoutConstant.candidateCharSize.width)
        
        return CandidateCell.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
}

extension CandidatePaneView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let candidateOrganizer = candidateOrganizer,
              let index = candidateOrganizer.getCandidateIndex(indexPath: indexPath) else { return }
        AudioFeedbackProvider.play(keyboardAction: .none)
        delegate?.candidatePaneViewCandidateSelected(index)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let candidateOrganizer = candidateOrganizer,
              let candidate = candidateOrganizer.getCandidate(indexPath: indexPath),
              let cell = cell as? CandidateCell else { return }
        let comment = candidateOrganizer.getCandidateComment(indexPath: indexPath)
        let showComment = candidateOrganizer.candidateSource is InputEngineCandidateSource &&
            (reverseLookupSchemaId != nil || Settings.cached.shouldShowRomanization && candidateOrganizer.inputMode != .english)
        cell.initLabel(candidate, comment, showComment: showComment)
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CandidateCell {
            cell.deinitLabel()
        }
    }
}
