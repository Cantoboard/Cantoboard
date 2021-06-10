//
//  CandidatePaneView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 1/5/21.
//  Copyright © 2021 Alex Man. All rights reserved.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

protocol CandidatePaneViewDelegate: NSObject {
    func candidatePaneViewExpanded()
    func candidatePaneViewCollapsed()
    func candidatePaneViewCandidateSelected(_ choice: IndexPath)
    func candidatePaneCandidateLoaded()
    func handleKey(_ action: KeyboardAction)
}

class StatusButton: UIButton {
    private static let statusInset: CGFloat = 4
    private weak var statusSquareBg: CALayer?
    var isMini: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
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
        
        titleLabel?.font = UIFont.systemFont(ofSize: isMini ? CandidatePaneView.miniStatusFontSize : LayoutConstants.forMainScreen.statusIndicatorFontSize)
        statusSquareBg?.frame = bounds.insetBy(dx: Self.statusInset, dy: Self.statusInset)
        statusSquareBg?.isHidden = isMini
        setTitleColor(isMini ? ButtonColor.keyHintColor : .label, for: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        statusSquareBg?.backgroundColor = ButtonColor.systemKeyBackgroundColor.resolvedColor(with: traitCollection).cgColor
    }
}

class CandidatePaneView: UIControl {
    private static let hapticsGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private static let miniStatusSize = CGSize(width: 20, height: 20)
    static let miniStatusFontSize: CGFloat = LayoutConstants.forMainScreen.miniStatusFontSize
    
    enum Mode {
        case row, table
    }
    
    enum StatusIndicatorMode {
        case lang, shape
    }
    
    let rowPadding = CGFloat(0)
        
    private var _keyboardState: KeyboardState
    
    var keyboardState: KeyboardState {
        get { _keyboardState }
        set {
            let prevState = _keyboardState
            let newState = newValue
            
            let isViewDirty = prevState.keyboardContextualType != newState.keyboardContextualType ||
                prevState.keyboardType != newValue.keyboardType ||
                prevState.inputMode != newState.inputMode ||
                prevState.activeSchema != newState.activeSchema
            
            _keyboardState = newValue
            
            if isViewDirty {
                setupButtons()
            }
        }
    }
    
    weak var candidateOrganizer: CandidateOrganizer? {
        didSet {
            candidateOrganizer?.onMoreCandidatesLoaded = { [weak self] candidateOrganizer in
                guard let self = self,
                      let collectionView = self.collectionView,
                      candidateOrganizer.groupByMode == .byFrequency else { return }
                let section = 1
                
                guard section < collectionView.numberOfSections else { return }
                
                let newIndiceStart = collectionView.numberOfItems(inSection: section)
                let newIndiceEnd = candidateOrganizer.getCandidateCount(section: 0)
                
                UIView.performWithoutAnimation {
                    if newIndiceStart > newIndiceEnd {
                        DDLogInfo("Reloading candidates onMoreCandidatesLoaded().")
                        
                        collectionView.reloadCandidates()
                    } else if newIndiceStart != newIndiceEnd {
                        DDLogInfo("Inserting new candidates: \(newIndiceStart)..<\(newIndiceEnd)")
                        collectionView.insertItems(at: (newIndiceStart..<newIndiceEnd).map { IndexPath(row: $0, section: section) })
                    }
                }
                self.delegate?.candidatePaneCandidateLoaded()
            }
            
            candidateOrganizer?.onReloadCandidates = { [weak self] candidateOrganizer in
                guard let self = self,
                      let collectionView = self.collectionView else { return }
                
                DDLogInfo("Reloading candidates.")
                
                UIView.performWithoutAnimation {
                    collectionView.scrollOnLayoutSubviews = {
                        let y = self.groupByEnabled ? LayoutConstants.forMainScreen.autoCompleteBarHeight : 0
                        
                        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
                        
                        return true
                    }
                    collectionView.reloadCandidates()
                }
            }
        }
    }
    private weak var collectionView: CandidateCollectionView!
    private weak var expandButton, backspaceButton, charFormButton: UIButton!
    private weak var inputModeButton: StatusButton!
    weak var delegate: CandidatePaneViewDelegate?
    private(set) var sectionHeaderWidth: CGFloat = LayoutConstants.forMainScreen.candidateCharSize.width * 2
    
    private(set) var mode: Mode = .row
    var statusIndicatorMode: StatusIndicatorMode {
        get {
            if keyboardState.keyboardType == .numeric ||
                keyboardState.keyboardType == .symbolic {
                return .shape
            } else {
                return .lang
            }
        }
    }
    
    init(keyboardState: KeyboardState) {
        _keyboardState = keyboardState
        super.init(frame: .zero)
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

        inputModeButton = (createAndAddButton(isStatusIndicator: true) as! StatusButton)
        inputModeButton.addTarget(self, action: #selector(self.filterButtonClick), for: .touchUpInside)
        sendSubviewToBack(inputModeButton)
        
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
    
    func setupButtons() {
        let expandButtonImage = mode == .row ? ButtonImage.paneExpandButtonImage : ButtonImage.paneCollapseButtonImage
        expandButton.setImage(expandButtonImage, for: .normal)
        
        var title: String?
        if statusIndicatorMode == .lang {
            switch keyboardState.inputMode {
            // TODO What to show in non jyut mixed mode???
            case .mixed: title = keyboardState.activeSchema.signChar // = "雙"
            case .chinese: title = keyboardState.activeSchema.signChar
            case .english: title = "英"
            }
        } else {
            switch keyboardState.symbolShape {
            case .full: title = "全"
            case .half: title = "半"
            default: title = nil
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
            inputModeButton.isMini = false
            inputModeButton.isUserInteractionEnabled = true
            backspaceButton.isHidden = false
            charFormButton.isHidden = keyboardState.activeSchema.isShapeBased
        } else {
            let cannotExpand =
                collectionView.contentSize.width <= 1 ||
                collectionView.contentSize.width < collectionView.bounds.width ||
                candidateOrganizer?.cannotExpand ?? false
            
            expandButton.isHidden = cannotExpand
            inputModeButton.isHidden = title == nil
            inputModeButton.isMini = !cannotExpand
            inputModeButton.isUserInteractionEnabled = cannotExpand
            backspaceButton.isHidden = true
            charFormButton.isHidden = true
        }
        
        setupContextMenu()
        setNeedsLayout()
    }
    
    private func setupContextMenu() {
        if #available(iOS 14.0, *) {
            expandButton.menu = nil
            inputModeButton.menu = nil
            
            let activeSchema = keyboardState.activeSchema
            let items = UIMenu(options: .displayInline, children: [
                UIAction(title: "粵拼", state: activeSchema == .jyutping ? .on : .off, handler: { [weak self] _ in self?.delegate?.handleKey(.changeSchema(.jyutping)) }),
                UIAction(title: "耶魯", state: activeSchema == .yale ? .on : .off, handler: { [weak self] _ in self?.delegate?.handleKey(.changeSchema(.yale)) }),
                UIAction(title: "倉頡", state: activeSchema == .cangjie ? .on : .off, handler: { [weak self] _ in self?.delegate?.handleKey(.changeSchema(.cangjie)) }),
                UIAction(title: "速成", state: activeSchema == .quick ? .on : .off, handler: { [weak self] _ in self?.delegate?.handleKey(.changeSchema(.quick)) }),
                UIAction(title: "普通話", state: activeSchema == .mandarin ? .on : .off, handler: { [weak self] _ in self?.delegate?.handleKey(.changeSchema(.mandarin)) }),
            ])
            
            if expandButton.isHidden {
                inputModeButton.menu = items
            } else {
                expandButton.menu = items
            }
        }
    }
    
    private func initCollectionView() {
        let collectionViewLayout = CandidateCollectionViewFlowLayout(candidatePaneView: self)
        
        let collectionView = CandidateCollectionView(frame :.zero, collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.reuseId)
        collectionView.register(CandidateSegmentControlCell.self, forCellWithReuseIdentifier: CandidateSegmentControlCell.reuseId)
        collectionView.register(CandidateSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CandidateSectionHeader.reuseId)
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
        Self.hapticsGenerator.impactOccurred(intensity: 1)
        AudioFeedbackProvider.play(keyboardAction: .none)
        
        if statusIndicatorMode == .lang {
            delegate?.handleKey(.toggleInputMode)
        } else {
            delegate?.handleKey(.toggleSymbolShape)
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
            if button == inputModeButton && inputModeButton.isMini {
                button.frame = CGRect(origin: CGPoint(x: bounds.size.width - Self.miniStatusSize.width, y: 0), size: Self.miniStatusSize)
                continue
            }
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
    func changeMode(_ newMode: Mode) {
        guard mode != newMode else { return }
        
        // DDLogInfo("CandidatePaneView.changeMode start")
        let firstVisibleIndexPath = getFirstVisibleIndexPath()
        
        mode = newMode
        
        setupButtons()
        
        if let scrollToIndexPath = firstVisibleIndexPath {
            let scrollToIndexPathDirection: UICollectionView.ScrollPosition = newMode == .row ? .left : .top
            if mode == .table && groupByEnabled && scrollToIndexPath.section <= 1 && scrollToIndexPath.row == 0 {
                collectionView.scrollOnLayoutSubviews = {
                    let candindateBarHeight = LayoutConstants.forMainScreen.autoCompleteBarHeight
                    
                    self.collectionView.setContentOffset(CGPoint(x: 0, y: candindateBarHeight), animated: false)
                    self.collectionView.showsVerticalScrollIndicator = true
                    
                    return true
                }
            } else {
                collectionView.scrollOnLayoutSubviews = {
                    guard let collectionView = self.collectionView else { return false }
                    
                    guard scrollToIndexPath.section < collectionView.numberOfSections else { return false }
                    let numberOfItems = collectionView.numberOfItems(inSection: scrollToIndexPath.section)
                    guard numberOfItems > scrollToIndexPath.row else { return false }
                    
                    collectionView.scrollToItem(
                        at: scrollToIndexPath,
                        at: scrollToIndexPathDirection, animated: false)
                    
                    collectionView.showsVerticalScrollIndicator = scrollToIndexPathDirection == .top
                    return true
                }
            }
        }
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = newMode == .row ? .horizontal : .vertical
            flowLayout.minimumLineSpacing = rowPadding
        }
        
        UIView.performWithoutAnimation { [self] in
            if newMode == .row && candidateOrganizer?.groupByMode != .byFrequency {
                candidateOrganizer?.groupByMode = .byFrequency
                collectionView.reloadData()
                collectionView.collectionViewLayout.invalidateLayout()
                collectionView.layoutIfNeeded()
            } else {
                // We have to reload collection view to add/remove the segment control.
                collectionView.reloadSections([0])
            }
        }
        
        collectionView.collectionViewLayout.invalidateLayout()
        layoutSubviews()
        
        if newMode == .row {
            delegate?.candidatePaneViewCollapsed()
        } else {
            delegate?.candidatePaneViewExpanded()
        }
        // DDLogInfo("CandidatePaneView.changeMode end")
    }
    
    func getFirstVisibleIndexPath() -> IndexPath? {
        let candidateCharSize = LayoutConstants.forMainScreen.candidateCharSize
        let firstAttempt = self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: candidateCharSize.width / 2, y: candidateCharSize.height / 2), to: self.collectionView))
        if firstAttempt != nil { return firstAttempt }
        return self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: candidateCharSize.width / 2, y: candidateCharSize.height / 2 + 2 * rowPadding), to: self.collectionView))
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        sectionHeaderWidth = LayoutConstants.forMainScreen.candidateCharSize.width * 2
        super.traitCollectionDidChange(previousTraitCollection)
    }
    
    func scrollToNextPageInRowMode() {
        guard mode == .row,
              let collectionView = self.collectionView else { return }
        var targetOffset = CGPoint(x: collectionView.contentOffset.x + collectionView.frame.width, y: collectionView.contentOffset.y)
        if let indexPathAtTargetOffset = collectionView.indexPathForItem(at: targetOffset),
           let cellAtTargetOffset = collectionView.cellForItem(at: indexPathAtTargetOffset) {
            targetOffset.x = cellAtTargetOffset.frame.minX
        }
        collectionView.setContentOffset(targetOffset, animated: true)
    }
}

extension CandidatePaneView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let candidateOrganizer = candidateOrganizer else { return 0 }
        return 1 + candidateOrganizer.getNumberOfSections()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let candidateOrganizer = candidateOrganizer else { return 0 }
        if section == 0 { return groupByEnabled ? 1 : 0 }
        return candidateOrganizer.getCandidateCount(section: translateCollectionViewSectionToCandidateSection(section))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if groupByEnabled && indexPath.section == 0 {
            return dequeueSegmentControl(collectionView, cellForItemAt: indexPath)
        } else {
            return dequeueCandidateCell(collectionView, cellForItemAt: indexPath)
        }
    }
    
    private func dequeueSegmentControl(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateSegmentControlCell.reuseId, for: indexPath) as! CandidateSegmentControlCell
        
        if let candidateOrganizer = candidateOrganizer {
            cell.setup(
                groupByModes: candidateOrganizer.supportedGroupByModes,
                selectedGroupByMode: candidateOrganizer.groupByMode,
                onSelectionChanged: onGroupBySegmentControlSelectionChanged)
        } else {
            DDLogInfo("Bug check. candidateOrganizer shouldn't be null.")
        }
        
        return cell
    }
    
    private func onGroupBySegmentControlSelectionChanged(_ groupByMode: GroupByMode) {
        guard let candidateOrganizer = candidateOrganizer else { return }
        
        candidateOrganizer.groupByMode = groupByMode
        
        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
    }
    
    private func dequeueCandidateCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.reuseId, for: indexPath) as! CandidateCell
        
        let candidateCount = self.collectionView.numberOfItems(inSection: translateCollectionViewSectionToCandidateSection(indexPath.section))
        if let candidateOrganizer = candidateOrganizer,
           candidateOrganizer.groupByMode == .byFrequency && indexPath.row >= candidateCount - 10 {
            DispatchQueue.main.async { [weak self] in
                guard self != nil else { return }
                if indexPath.row >= candidateOrganizer.getCandidateCount(section: 0) - 10 {
                    candidateOrganizer.requestMoreCandidates(section: 0)
                }
            }
        }
        
        return cell
    }
    
    var groupByEnabled: Bool {
        mode == .table && (candidateOrganizer?.supportedGroupByModes.count ?? 0 > 1)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CandidateSectionHeader.reuseId, for: indexPath) as! CandidateSectionHeader
        
        let section = translateCollectionViewSectionToCandidateSection(indexPath.section)
        let text = candidateOrganizer?.getSectionHeader(section: section) ?? ""
        header.setup(text, autoSize: candidateOrganizer?.groupByMode == .byRomanization)
        
        return header
    }
}

extension CandidatePaneView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            if groupByEnabled {
                let height = LayoutConstants.forMainScreen.autoCompleteBarHeight
                let width = collectionView.bounds.width
                return CGSize(width: width, height: height)
            } else {
                return .zero
            }

        } else {
            return computeCellSize(candidateIndexPath: translateCollectionViewIndexPathToCandidateIndexPath(indexPath))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if hasNoHeader(section: section) {
            return .zero
        } else {
            return UIEdgeInsets(top: 0, left: sectionHeaderWidth, bottom: 0, right: 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if hasNoHeader(section: section) {
            return .zero
        } else {
            // layoutAttributesForSupplementaryView() will move the section from the top to the left.
            return CGSize(width: 0, height: CGFloat.leastNonzeroMagnitude)
        }
    }
    
    private func hasNoHeader(section: Int) -> Bool {
        return mode == .row || candidateOrganizer?.groupByMode == .byFrequency || section == 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if mode == .row {
            return 0
        } else {
            return rowPadding
        }
    }
    
    private func computeCellSize(candidateIndexPath: IndexPath) -> CGSize {
        guard let candidateOrganizer = candidateOrganizer else { return .zero }
        let layoutConstant = LayoutConstants.forMainScreen
        
        guard let text = candidateOrganizer.getCandidate(indexPath: candidateIndexPath) else {
            DDLogInfo("Invalid IndexPath \(candidateIndexPath.description). Candidate does not exist.")
            return .zero
        }
        
        var cellWidth = text.size(withFont: UIFont.systemFont(ofSize: layoutConstant.candidateFontSize)).width
        let cellHeight = LayoutConstants.forMainScreen.autoCompleteBarHeight
        
        if showComment {
            let comment = candidateOrganizer.getCandidateComment(indexPath: candidateIndexPath)
            let commentWidth = comment?.size(withFont: UIFont.systemFont(ofSize: layoutConstant.candidateCommentFontSize)).width ?? 0
            cellWidth = max(cellWidth, commentWidth)
            cellWidth = max(cellWidth, layoutConstant.candidateCharSize.width * 1.45)
        } else {
            // Min width add 30% padding
            cellWidth = max(cellWidth, layoutConstant.candidateCharSize.width * 1.3)
        }
        
        return CandidateCell.margin.wrap(widthOnly: CGSize(width: cellWidth, height: cellHeight))
    }
    
    private var showComment: Bool {
        keyboardState.activeSchema != .jyutping || Settings.cached.shouldShowRomanization
    }
    
    private func translateCollectionViewIndexPathToCandidateIndexPath(_ collectionViewIndexPath: IndexPath) -> IndexPath {
        return IndexPath(row: collectionViewIndexPath.row, section: collectionViewIndexPath.section - 1)
    }
    
    private func translateCollectionViewSectionToCandidateSection(_ collectionViewSection: Int) -> Int {
        return collectionViewSection - 1
    }
}

extension CandidatePaneView: CandidateCollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section > 0 else { return }
        
        AudioFeedbackProvider.play(keyboardAction: .none)
        delegate?.candidatePaneViewCandidateSelected(translateCollectionViewIndexPathToCandidateIndexPath(indexPath))
    }
    
    func collectionView(_ collectionView: UICollectionView, didLongPressItemAt indexPath: IndexPath) {
        delegate?.handleKey(.longPressCandidate(translateCollectionViewIndexPathToCandidateIndexPath(indexPath)))
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let candidateOrganizer = candidateOrganizer else { return }
        if let cell = cell as? CandidateSegmentControlCell {
            cell.update(selectedGroupByMode: candidateOrganizer.groupByMode)
        } else if let cell = cell as? CandidateCell {
            let candidateIndexPath = translateCollectionViewIndexPathToCandidateIndexPath(indexPath)
            guard let candidate = candidateOrganizer.getCandidate(indexPath: candidateIndexPath) else { return }
            let comment = candidateOrganizer.getCandidateComment(indexPath: candidateIndexPath)
            cell.frame = CGRect(origin: cell.frame.origin, size: computeCellSize(candidateIndexPath: candidateIndexPath))
            cell.setup(candidate, comment, showComment: showComment)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CandidateCell {
            cell.free()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, at indexPath: IndexPath) {
        if let view = view as? CandidateSectionHeader {
            view.free()
        }
    }
}
