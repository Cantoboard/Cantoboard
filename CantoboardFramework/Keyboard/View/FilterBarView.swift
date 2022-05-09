//
//  FilterBarView.swift
//  CantoboardFramework
//
//  Created by Alex Man on 2/11/22.
//

import Foundation
import UIKit

class FilterBarView: UIView {
    private var _keyboardState: KeyboardState
    var keyboardState: KeyboardState {
        get { _keyboardState }
        set { changeState(prevState: _keyboardState, newState: newValue) }
    }
    
    private weak var filterCollectionView: UICollectionView?
    private weak var separatorLayer: CALayer?
    weak var delegate: KeyboardViewDelegate?

    init(keyboardState: KeyboardState) {
        _keyboardState = keyboardState
        super.init(frame: .zero)
        backgroundColor = .clear
        
        let separatorLayer = CALayer()
        separatorLayer.backgroundColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
        layer.addSublayer(separatorLayer)
        self.separatorLayer = separatorLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func changeState(prevState: KeyboardState, newState: KeyboardState) {
        _keyboardState = newState
        
        let isViewDirty = prevState.tenKeysState != newState.tenKeysState
        
        if isViewDirty {
            updateView()
        }
        
        if let filterCollectionView = filterCollectionView {
            let selectedFilterIndexPath = newState.tenKeysState.selectedSpecializationCandidateIndex
                .filter({ $0 < filterCollectionView.numberOfItems(inSection: 0) })
                .map({ IndexPath(row: $0, section: 0) })
            filterCollectionView.selectItem(at: selectedFilterIndexPath, animated: false, scrollPosition: .right)
        }
    }
    
    func updateView() {
        if filterCollectionView == nil {
            let collectionViewFlowLayout = UICollectionViewFlowLayout()
            collectionViewFlowLayout.scrollDirection = .horizontal
            
            let filterCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
            addSubview(filterCollectionView)
            filterCollectionView.translatesAutoresizingMaskIntoConstraints = false
            filterCollectionView.dataSource = self
            filterCollectionView.delegate = self
            filterCollectionView.register(CandidateCell.self, forCellWithReuseIdentifier: CandidateCell.reuseId)
            filterCollectionView.backgroundColor = .clear
            filterCollectionView.allowsSelection = true
            self.filterCollectionView = filterCollectionView
        }
        
        let filterCollectionView = filterCollectionView!
        filterCollectionView.reloadData()

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let separatorHeight = CGFloat(1)
        separatorLayer?.frame = CGRect(x: 0, y: bounds.height - separatorHeight, width: bounds.width, height: separatorHeight)
        filterCollectionView?.frame = bounds
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        separatorLayer?.backgroundColor = UIColor.separator.resolvedColor(with: traitCollection).cgColor
    }
}

extension FilterBarView: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return keyboardState.tenKeysState.specializationCandidates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CandidateCell.reuseId, for: indexPath) as! CandidateCell
        cell.isFilterCell = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let text = keyboardState.tenKeysState.specializationCandidates[safe: indexPath.row],
           let cell = cell as? CandidateCell {
            cell.setup(text, nil, showComment: false)
            if indexPath.row == keyboardState.tenKeysState.selectedSpecializationCandidateIndex {
                cell.isSelected = true
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? CandidateCell {
            cell.free()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if let text = keyboardState.tenKeysState.specializationCandidates[safe: indexPath.row] {
            return CandidateCell.computeCellSize(cellHeight: bounds.height, minWidth: bounds.height * 1.25, candidateText: text, comment: nil)
        }
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.handleKey(.selectTenKeysSpecialization(indexPath.row))
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        collectionView.selectItem(at: nil, animated: false, scrollPosition: .left)
    }
}
