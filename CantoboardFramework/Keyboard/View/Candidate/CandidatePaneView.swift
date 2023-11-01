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
    func handleStatusMenu(from: UIView, with: UIEvent?) -> Bool
}

class CandidatePaneView: UIControl {
    private static let miniStatusSize = CGSize(width: 20, height: 20)
    private static let separatorWidth: CGFloat = 1
    
    // Uncomment this to debug memory leak.
    private let c = InstanceCounter<CandidatePaneView>()
    
    enum Mode {
        case row, table
    }
    
    enum StatusIndicatorMode {
        case lang, shape
    }
    
    let rowPadding = CGFloat(0)
    
    private var _keyboardState: KeyboardState
    private var layoutConstants: Reference<LayoutConstants>
    private var setNeedsSetupButtons = false
    
    var keyboardState: KeyboardState {
        get { _keyboardState }
        set {
            let prevState = _keyboardState
            let newState = newValue
            
            let isViewDirty = prevState.keyboardContextualType != newState.keyboardContextualType ||
                prevState.keyboardType != newValue.keyboardType ||
                prevState.inputMode != newState.inputMode ||
                prevState.activeSchema != newState.activeSchema ||
                prevState.keyboardIdiom != newState.keyboardIdiom ||
                prevState.symbolShape != newState.symbolShape ||
                prevState.enableState != newValue.enableState
            
            _keyboardState = newValue
            
            if isViewDirty {
                setupButtons()
            }
        }
    }
    
    private var _candidateOrganizer: CandidateOrganizer?
    public var candidateOrganizer: CandidateOrganizer? {
        get { _candidateOrganizer }
        set {
            guard newValue !== _candidateOrganizer else { return }
            
            _candidateOrganizer?.onMoreCandidatesLoaded = nil
            _candidateOrganizer?.onReloadCandidates = nil
            _candidateOrganizer = newValue
            
            if let candidateOrganizer = _candidateOrganizer {
                candidateOrganizer.onMoreCandidatesLoaded = { [weak self] candidateOrganizer in
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
                
                candidateOrganizer.onReloadCandidates = { [weak self] candidateOrganizer in
                    guard let self = self else { return }
                    
                    DDLogInfo("Reloading candidates.")
                    
                    let originalCandidatePaneMode = self.mode
                    let originalContentOffset: CGPoint = self.collectionView.contentOffset
                    
                    self.setNeedsSetupButtons = true
                    
                    UIView.performWithoutAnimation {
                        self.collectionView.scrollOnLayoutSubviews = { [weak self] in
                            guard let self = self,
                                  let collectionView = self.collectionView else { return true }
                            if originalCandidatePaneMode == self.mode && self.shouldPreserveCandidateOffset {
                                if originalCandidatePaneMode == .table  {
                                    // Preserve contentOffset on toggling charForm
                                    let clampedOffset = CGPoint(x: 0, y: min(originalContentOffset.y, max(0, collectionView.contentSize.height - self.rowHeight)))
                                    collectionView.setContentOffset(clampedOffset, animated: false)
                                } else {
                                    // Preserve contentOffset on toggling unlearn
                                    let clampedOffset = CGPoint(x: min(originalContentOffset.x, max(0, collectionView.contentSize.width - collectionView.bounds.width)), y: 0)
                                    collectionView.setContentOffset(clampedOffset, animated: false)
                                }
                            } else {
                                let y = self.groupByEnabled ? self.rowHeight : 0
                                
                                collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: false)
                            }
                            
                            self.shouldPreserveCandidateOffset = false
                            return true
                        }
                        self.collectionView.reloadCandidates()
                        if self.collectionView.numberOfSections < 1 ||
                            self.collectionView(self.collectionView, numberOfItemsInSection: 1) == 0 {
                            self.changeMode(.row)
                        }
                    }
                }
            }
        }
    }
    
    private weak var collectionView: CandidateCollectionView!
    private weak var backspaceButton, charFormButton, scrollUpButton, scrollDownButton: UIButton!
    private weak var expandButton, inputModeButton: StatusButton!
    private weak var leftSeparator, middleSeparator, rightSeparator: UIView!
    weak var delegate: CandidatePaneViewDelegate?
    
    private(set) var mode: Mode = .row
    private var shouldPreserveCandidateOffset: Bool = false
    
    var statusIndicatorMode: StatusIndicatorMode {
        get {
            if keyboardState.keyboardType == .numeric ||
               keyboardState.keyboardType == .symbolic ||
               keyboardState.keyboardType == .numSymbolic {
                return .shape
            } else {
                return .lang
            }
        }
    }
    
    private var _canExpand: Bool = false
    var canExpand: Bool {
        get { _canExpand }
        set {
            guard _canExpand != newValue || setNeedsSetupButtons else { return }
            _canExpand = newValue
            setNeedsSetupButtons = false
            setupButtons()
        }
    }
    
    init(keyboardState: KeyboardState, layoutConstants: Reference<LayoutConstants>) {
        _keyboardState = keyboardState
        self.layoutConstants = layoutConstants
        
        super.init(frame: .zero)
        
        translatesAutoresizingMaskIntoConstraints = false
        
        createCollectionView()
        createButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var shouldShowStatusMenu: Bool {
        if keyboardState.inputMode != .english && mode == .row,
           case .alphabetic = keyboardState.keyboardType {
            return true
        }
        return false
    }
    
    private func createButtons() {
        expandButton = createAndAddButton(StatusButton())
        expandButton.addTarget(self, action: #selector(self.expandButtonClick), for: .touchUpInside)
        expandButton.shouldShowStatusBackground = false
        expandButton.handleStatusMenu = { [weak self] in
            guard let self = self else { return false }
            guard self.expandButton.shouldShowMenuIndicator else { return false }
            return self.handleStatusMenu(from: $0, with: $1)
        }
        
        inputModeButton = createAndAddButton(StatusButton())
        inputModeButton.addTarget(self, action: #selector(self.filterButtonClick), for: .touchUpInside)
        inputModeButton.handleStatusMenu = { [weak self] in
            return self?.handleStatusMenu(from: $0, with: $1) ?? false
        }
        
        backspaceButton = createAndAddButton(UIButton())
        backspaceButton.addTarget(self, action: #selector(self.backspaceButtonClick), for: .touchUpInside)
        
        charFormButton = createAndAddButton(StatusButton())
        charFormButton.addTarget(self, action: #selector(self.charFormButtonClick), for: .touchUpInside)
        
        scrollUpButton = createAndAddButton(UIButton())
        scrollUpButton.addTarget(self, action: #selector(self.scrollUpButtonClick), for: .touchUpInside)
        
        scrollDownButton = createAndAddButton(UIButton())
        scrollDownButton.addTarget(self, action: #selector(self.scrollDownButtonClick), for: .touchUpInside)
    }
    
    private func createAndAddButton<T: UIButton>(_ button: T) -> T {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.contentsFormat = .gray8Uint
        // button.layer.cornerRadius = 5
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label
        // button.highlightedBackgroundColor = self.HIGHLIGHTED_COLOR
        
        addSubview(button)
        return button
    }
    
    func setupButtons() {
        var expandButtonImage: UIImage
        switch Settings.cached.candidateSelectMode {
        case .expandDownward:
            expandButtonImage = mode == .row ? ButtonImage.paneExpandButtonImage : ButtonImage.paneCollapseButtonImage
        case .scrollRight:
            if !collectionView.isAtRightmostPosition {
                expandButtonImage = ButtonImage.paneScrollRightButtonImage
            } else {
                expandButtonImage = ButtonImage.paneScrollToBeginningButtonImage
            }
        }
        expandButton.setImage(adjustImageFontSize(expandButtonImage), for: .normal)
        expandButton.shouldShowMenuIndicator = mode == .row
        expandButton.isEnabled = keyboardState.enableState == .enabled
        
        var title: String?
        var shouldShowMiniIndicator = false
        if statusIndicatorMode == .lang {
            shouldShowMiniIndicator = true
            switch keyboardState.inputMode {
            case .mixed: title = keyboardState.activeSchema.signChar
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
        
        let isKeyboardEnabled = keyboardState.enableState == .enabled
        
        inputModeButton.setTitle(title, for: .normal)
        inputModeButton.shouldShowMenuIndicator = shouldShowMiniIndicator && mode == .row
        inputModeButton.isEnabled = isKeyboardEnabled

        backspaceButton.setImage(adjustImageFontSize(ButtonImage.backspace), for: .normal)
        backspaceButton.setImage(adjustImageFontSize(ButtonImage.backspaceFilled), for: .highlighted)
        backspaceButton.isEnabled = isKeyboardEnabled
        
        scrollUpButton.setImage(tintWithLabel(adjustImageFontSize(ButtonImage.paneScrollUpButtonImage)), for: .normal)
        //scrollUpButton.setImage(adjustImageFontSize(ButtonImage.paneScrollUpHighlightedButtonImage), for: .highlighted)
        scrollUpButton.isEnabled = isKeyboardEnabled && collectionView.contentOffset.y > rowHeight

        scrollDownButton.setImage(tintWithLabel(adjustImageFontSize(ButtonImage.paneScrollDownButtonImage)), for: .normal)
        //scrollDownButton.setImage(adjustImageFontSize(ButtonImage.paneScrollDownHighlightedButtonImage), for: .highlighted)
        scrollDownButton.isEnabled = isKeyboardEnabled && collectionView.contentOffset.y < collectionView.contentSize.height - collectionView.frame.height - 0.25 * rowHeight

        let charFormText = SessionState.main.lastCharForm.caption
        charFormButton.setTitle(charFormText, for: .normal)
        charFormButton.isEnabled = keyboardState.enableState == .enabled
        
        if mode == .table {
            expandButton.isHidden = false
            inputModeButton.isHidden = false || title == nil
            inputModeButton.isMini = false
            inputModeButton.isUserInteractionEnabled = true
            backspaceButton.isHidden = false
            // Always show char form toggle for switching predictive text.
            charFormButton.isHidden = false
            scrollUpButton.isHidden = false
            scrollDownButton.isHidden = false
        } else {
            let cannotExpand = !keyboardState.keyboardType.isAlphabetic ||
                               collectionView.visibleCells.isEmpty ||
                               !canExpand ||
                               keyboardState.enableState != .enabled ||
                               candidateOrganizer?.cannotExpand ?? true
            
            expandButton.isHidden = cannotExpand
            inputModeButton.isHidden = title == nil
            inputModeButton.isMini = !cannotExpand
            inputModeButton.isUserInteractionEnabled = cannotExpand
            backspaceButton.isHidden = true
            charFormButton.isHidden = true
            scrollUpButton.isHidden = true
            scrollDownButton.isHidden = true
        }
        
        layoutButtons()
    }
    
    private func handleStatusMenu(from: UIView, with: UIEvent?) -> Bool {
        return delegate?.handleStatusMenu(from: from, with: with) ?? false
    }
    
    private func createCollectionView() {
        let collectionViewLayout = CandidateCollectionViewFlowLayout(candidatePaneView: self)
        collectionViewLayout.scrollDirection = mode == .row ? .horizontal : .vertical
        collectionViewLayout.minimumLineSpacing = rowPadding
        
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
        
        self.addSubview(collectionView)
        self.collectionView = collectionView
        
        let leftSeparator = UIView()
        leftSeparator.backgroundColor = .separator
        self.addSubview(leftSeparator)
        self.leftSeparator = leftSeparator
        
        let middleSeparator = UIView()
        middleSeparator.backgroundColor = .separator
        self.addSubview(middleSeparator)
        self.middleSeparator = middleSeparator
        
        let rightSeparator = UIView()
        rightSeparator.backgroundColor = .separator
        self.addSubview(rightSeparator)
        self.rightSeparator = rightSeparator
    }
    
    override func didMoveToSuperview() {
        self.needsUpdateConstraints()
        self.updateConstraints() // TODO revisit
    }
    
    var rowHeight: CGFloat {
        layoutConstants.ref.autoCompleteBarHeight
    }
    
    private var expandButtonWidth: CGFloat {
        rowHeight // Square
    }
    
    var sectionHeaderWidth: CGFloat {
        rowHeight // Square
    }
    
    @objc private func expandButtonClick() {
        FeedbackProvider.rigidImpact.impactOccurred()
        
        switch Settings.cached.candidateSelectMode {
        case .expandDownward:
            changeMode(mode == .row ? .table : .row)
        case .scrollRight:
            scrollRightToNextPageInRowMode()
        }
    }
    
    @objc private func filterButtonClick() {
        FeedbackProvider.rigidImpact.impactOccurred()
        FeedbackProvider.play(keyboardAction: .none)
        
        if statusIndicatorMode == .lang {
            delegate?.handleKey(.toggleInputMode(keyboardState.inputMode.afterToggle))
        } else {
            delegate?.handleKey(.toggleSymbolShape)
        }
    }
    
    @objc private func backspaceButtonClick() {
        FeedbackProvider.play(keyboardAction: .backspace)
        delegate?.handleKey(.backspace)
    }
    
    @objc private func charFormButtonClick() {
        FeedbackProvider.rigidImpact.impactOccurred()
        FeedbackProvider.play(keyboardAction: .none)
        
        let currentCharForm = SessionState.main.lastCharForm
        let newCharForm: CharForm = currentCharForm == .simplified ? .traditional : .simplified
        delegate?.handleKey(.setCharForm(newCharForm))
        setupButtons()
    }
    
    @objc private func scrollUpButtonClick() {
        scrollButtonClick(isScrollingUp: true)
    }
    
    @objc private func scrollDownButtonClick() {
        scrollButtonClick(isScrollingUp: false)
    }
    
    @objc private func scrollButtonClick(isScrollingUp: Bool) {
        FeedbackProvider.rigidImpact.impactOccurred()
        FeedbackProvider.play(keyboardAction: .none)
        
        scrollInTableMode(isScrollingUp: isScrollingUp)
        
        setupButtons()
    }
    
    private func handleKey(_ action: KeyboardAction) {
        delegate?.handleKey(action)
    }
    
    private var isFullPadCandidateBar: Bool {
        let isPhone = layoutConstants.ref.idiom == .phone
        return isPhone || Settings.cached.fullPadCandidateBar
    }
    
    override func layoutSubviews() {
        guard let superview = superview else { return }
        
        let height = mode == .row ? rowHeight : superview.bounds.height
        let candidateViewWidth = superview.bounds.width - expandButtonWidth
        let leftRightInset = isFullPadCandidateBar ? 0 : layoutConstants.ref.candidatePaneViewLeftRightInset
        
        let collectionViewFrame = CGRect(x: leftRightInset, y: 0, width: candidateViewWidth - leftRightInset * 2, height: height)
        if collectionView.frame != collectionViewFrame {
            collectionView.frame = collectionViewFrame
            collectionView.collectionViewLayout.invalidateLayout()
        }
        
        super.layoutSubviews()
        layoutButtons()
        
        let topBottomMargin: CGFloat = mode == .row ? 8 : 0
        let separatorFrame = CGRect(x: 0, y: topBottomMargin, width: Self.separatorWidth, height: height - topBottomMargin * 2)
        
        if isFullPadCandidateBar {
            leftSeparator.isHidden = true
        } else {
            leftSeparator.isHidden = false
            leftSeparator.frame = separatorFrame.with(x: leftRightInset - Self.separatorWidth)
        }
        
        if expandButton.isHidden {
            middleSeparator.isHidden = true
        } else {
            middleSeparator.isHidden = false
            middleSeparator.frame = separatorFrame.with(x: candidateViewWidth - leftRightInset)
        }
        
        if mode == .table || isFullPadCandidateBar {
            rightSeparator.isHidden = true
        } else {
            rightSeparator.isHidden = false
            rightSeparator.frame = separatorFrame.with(x: superview.bounds.width - leftRightInset)
        }
    }
    
    private func layoutButtons() {
        guard let superview = superview else { return }
        
        let buttons = [expandButton, inputModeButton, backspaceButton, charFormButton, scrollUpButton, scrollDownButton]
        var buttonY: CGFloat = 0
        let candidatePaneViewLeftRightInset = isFullPadCandidateBar ? 0 : layoutConstants.ref.candidatePaneViewLeftRightInset
        let candidateViewWidth = superview.bounds.width - (expandButton.isHidden ? directionalLayoutMargins.trailing - StatusButton.statusInset : candidatePaneViewLeftRightInset)
        for button in buttons {
            guard let button = button, !button.isHidden else { continue }
            if button == inputModeButton && inputModeButton.isMini {
                button.frame = CGRect(origin: CGPoint(x: candidateViewWidth - Self.miniStatusSize.width, y: 0), size: Self.miniStatusSize)
                continue
            }
            button.frame = CGRect(origin: CGPoint(x: candidateViewWidth - expandButtonWidth, y: buttonY), size: CGSize(width: expandButtonWidth, height: expandButtonWidth))
            buttonY += rowHeight
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
    
    private func adjustImageFontSize(_ image: UIImage) -> UIImage {
        image.withConfiguration(UIImage.SymbolConfiguration(pointSize: keyboardState.keyboardIdiom.isPad ? 24 : 20))
    }
    
    private func tintWithLabel(_ image: UIImage) -> UIImage {
        image.withTintColor(.label)
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
                collectionView.scrollOnLayoutSubviews = { [weak self] in
                    guard let self = self else { return true }
                    let candindateBarHeight = self.rowHeight
                    
                    self.collectionView.setContentOffset(CGPoint(x: 0, y: candindateBarHeight), animated: false)
                    self.collectionView.showsVerticalScrollIndicator = true
                    
                    return true
                }
            } else {
                collectionView.scrollOnLayoutSubviews = { [weak self] in
                    guard let self = self else { return true }
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
        
        if let candidateOrganizer = candidateOrganizer {
            UIView.performWithoutAnimation { [self] in
                if newMode == .row && candidateOrganizer.groupByMode != .byFrequency {
                    candidateOrganizer.groupByMode = .byFrequency
                    collectionView.reloadData()
                    collectionView.collectionViewLayout.invalidateLayout()
                    collectionView.layoutIfNeeded()
                } else {
                    // We have to reload collection view to add/remove the segment control.
                    collectionView.reloadSections([0])
                }
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
        let candidateCharSize = CGSize(width: rowHeight, height: rowHeight)
        let firstAttempt = self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: candidateCharSize.width / 2, y: candidateCharSize.height / 2), to: self.collectionView))
        if firstAttempt != nil { return firstAttempt }
        return self.collectionView.indexPathForItem(at: self.convert(CGPoint(x: candidateCharSize.width / 2, y: candidateCharSize.height / 2 + 2 * rowHeight), to: self.collectionView))
    }
    
    func scrollRightToNextPageInRowMode() {
        let candidateCellMarginWidth = CandidateCell.margin.left + CandidateCell.margin.right
        guard mode == .row,
              let collectionView = self.collectionView else { return }
        
        guard !collectionView.isAtRightmostPosition else {
            let origin = CGPoint(x: 0, y: collectionView.contentOffset.y)
            collectionView.scrollRectToVisible(CGRect(origin: origin, size: CGSize(width: 1, height: 1)), animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                FeedbackProvider.rigidImpact.impactOccurred()
            })
            return
        }
        
        var targetOffset = CGPoint(x: collectionView.contentOffset.x + collectionView.frame.width + candidateCellMarginWidth, y: collectionView.contentOffset.y)
        if let indexPathAtTargetOffset = collectionView.indexPathForItem(at: targetOffset),
           let cellAtTargetOffset = collectionView.cellForItem(at: indexPathAtTargetOffset) {
            targetOffset.x = cellAtTargetOffset.frame.minX
        }
        targetOffset.x = max(0, min(targetOffset.x, collectionView.contentSize.width - collectionView.frame.width))
        collectionView.setContentOffset(targetOffset, animated: true)
    }
    
    func scrollInTableMode(isScrollingUp: Bool) {
        let candidateCellMarginHeight = CandidateCell.margin.top + CandidateCell.margin.bottom
        guard mode == .table,
              let collectionView = self.collectionView else { return }
        
        let numOfRowsOfCandidatePerPage = floor((collectionView.frame.height / rowHeight) + 0.25)

        let offsetY = (isScrollingUp ? -1 : 1) * numOfRowsOfCandidatePerPage * rowHeight
        var targetOffset = CGPoint(x: collectionView.contentOffset.x + 15, y: collectionView.contentOffset.y + offsetY)
        if let indexPathAtTargetOffset = collectionView.indexPathForItem(at: targetOffset),
           let cellAtTargetOffset = collectionView.cellForItem(at: indexPathAtTargetOffset) {
            targetOffset.y = cellAtTargetOffset.frame.minY
        }
        targetOffset.x = collectionView.contentOffset.x
        targetOffset.y = targetOffset.y.clamped(to: rowHeight...collectionView.contentSize.height - collectionView.frame.height)
        collectionView.setContentOffset(targetOffset, animated: true)
    }
    
    func setPreserveCandidateOffset() {
        shouldPreserveCandidateOffset = true
    }
}

extension CandidatePaneView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1 + (candidateOrganizer?.getNumberOfSections() ?? 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return groupByEnabled ? 1 : 0 }
        return candidateOrganizer?.getCandidateCount(section: translateCollectionViewSectionToCandidateSection(section)) ?? 0
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
        
        guard let candidateOrganizer = candidateOrganizer else { return cell }
        cell.setup(
            groupByModes: candidateOrganizer.supportedGroupByModes,
            selectedGroupByMode: candidateOrganizer.groupByMode,
            onSelectionChanged: { [weak self] in self?.onGroupBySegmentControlSelectionChanged($0) })
        
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
        guard let candidateOrganizer = candidateOrganizer else { return cell }
        
        let candidateCount = self.collectionView.numberOfItems(inSection: translateCollectionViewSectionToCandidateSection(indexPath.section))
        if candidateOrganizer.groupByMode == .byFrequency && indexPath.row >= candidateCount - 10 {
            DispatchQueue.main.async {
                if indexPath.row >= candidateOrganizer.getCandidateCount(section: 0) - 10 {
                    candidateOrganizer.requestMoreCandidates(section: 0)
                }
            }
        }
        
        return cell
    }
    
    var groupByEnabled: Bool {
        mode == .table && (candidateOrganizer?.supportedGroupByModes.count ?? 0) > 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CandidateSectionHeader.reuseId, for: indexPath) as! CandidateSectionHeader
        
        let section = translateCollectionViewSectionToCandidateSection(indexPath.section)
        let text = candidateOrganizer?.getSectionHeader(section: section) ?? ""
        header.layoutConstants = layoutConstants
        header.setup(text)
        
        return header
    }
}

extension CandidatePaneView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            if groupByEnabled {
                // TODO revisit could we remove this.
                let height = rowHeight
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
        let layoutConstants = layoutConstants.ref
        guard let text = candidateOrganizer?.getCandidate(indexPath: candidateIndexPath) else {
            DDLogInfo("Invalid IndexPath \(candidateIndexPath.description). Candidate does not exist.")
            return .zero
        }
        
        let comment = showComment ? candidateOrganizer?.getCandidateComment(indexPath: candidateIndexPath) : nil
        
        let numOfSingleCharCandidateInRow = CGFloat(layoutConstants.numOfSingleCharCandidateInRow)
        return CandidateCell.computeCellSize(
            cellHeight: rowHeight, minWidth: (bounds.width - expandButtonWidth) / numOfSingleCharCandidateInRow,
            candidateText: text, comment: comment)
    }
    
    private var showComment: Bool {
        switch Settings.cached.showRomanizationMode {
        case .never: return keyboardState.reverseLookupSchema != nil
        case .always: return true
        case .onlyInNonCantoneseMode: return !keyboardState.activeSchema.isCantonese
        }
    }
    
    private func translateCollectionViewIndexPathToCandidateIndexPath(_ collectionViewIndexPath: IndexPath) -> IndexPath {
        return IndexPath(row: collectionViewIndexPath.row, section: collectionViewIndexPath.section - 1)
    }
    
    private func translateCollectionViewSectionToCandidateSection(_ collectionViewSection: Int) -> Int {
        return collectionViewSection - 1
    }
}

extension CandidatePaneView: CandidateCollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section > 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CandidateCell {
            cell.isSelected = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CandidateCell {
            cell.isSelected = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section > 0 else { return }
        
        FeedbackProvider.play(keyboardAction: .none)
        if Settings.cached.isTapHapticFeedbackEnabled {
            FeedbackProvider.lightImpact.impactOccurred()
        }
        delegate?.candidatePaneViewCandidateSelected(translateCollectionViewIndexPathToCandidateIndexPath(indexPath))
    }
    
    func collectionView(_ collectionView: UICollectionView, didLongPressItemAt indexPath: IndexPath) {
        self.collectionView(collectionView, didUnhighlightItemAt: indexPath)
        
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        setupButtons()
    }
}

class SimpleHighlightableButton: UIButton {
    override open var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? .systemGray6.withAlphaComponent(0.5) : nil
        }
    }
}
