//
//  CategoriesBottomView.swift
//  ISEmojiView
//
//  Created by Beniamin Sarkisyan on 01/08/2018.
//

import Foundation

private let MinCellSize = CGFloat(35)

internal protocol CategoriesBottomViewDelegate: class {
    
    func categoriesBottomViewDidSelecteCategory(_ category: Category, percentage: Double, bottomView: CategoriesBottomView)
    func categoriesBottomViewDidPressChangeKeyboardButton(_ bottomView: CategoriesBottomView)
    func categoriesBottomViewDidPressDeleteBackwardButton(_ bottomView: CategoriesBottomView)
    
}

final internal class CategoriesBottomView: UIView {
    
    // MARK: - Internal variables
    
    internal weak var delegate: CategoriesBottomViewDelegate?
    internal var needToShowAbcButton: Bool? {
        didSet {
            guard let showAbcButton = needToShowAbcButton else {
                return
            }
            
            changeKeyboardButton.isHidden = !showAbcButton
            collectionViewToSuperViewLeadingConstraint.priority = showAbcButton ? .defaultHigh : .defaultLow
        }
    }
    
    internal var categories: [Category]! {
        didSet {
            collectionView.reloadData()
            
            if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.isEmpty {
                selectFirstCell()
            }
        }
    }
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var changeKeyboardButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton! {
        didSet {
            let image = UIImage(named: "ic_emojiDelete", in: Bundle.podBundle,compatibleWith: nil)
            deleteButton.setImage(image, for: .normal)
        }
    }
    
    @IBOutlet private weak var collectionView: UICollectionView! {
        didSet {
            collectionView.isUserInteractionEnabled = false
            collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        }
    }
    
    @IBOutlet private var collectionViewToSuperViewLeadingConstraint: NSLayoutConstraint!
    
    private var selectPercentage: Double = 0
    private var touchBeganPoint: CGPoint? = nil
    
    // MARK: - Init functions
    
    static internal func loadFromNib(with categories: [Category], needToShowAbcButton: Bool) -> CategoriesBottomView {
        let nibName = String(describing: CategoriesBottomView.self)
        
        guard let nib = Bundle.podBundle.loadNibNamed(nibName, owner: nil, options: nil) as? [CategoriesBottomView] else {
            fatalError()
        }
        
        guard let bottomView = nib.first else {
            fatalError()
        }
        
        bottomView.categories = categories
        bottomView.changeKeyboardButton.isHidden = !needToShowAbcButton
        
        if needToShowAbcButton {
            bottomView.collectionViewToSuperViewLeadingConstraint.priority = .defaultHigh
        }
        
        bottomView.selectFirstCell()
        
        return bottomView
    }
    
    // MARK: - Override functions
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            var size = collectionView.bounds.size
            
            if categories.count < Category.count - 2 {
                size.width = MinCellSize
            } else {
                size.width = collectionView.bounds.width/CGFloat(categories.count)
            }
            
            layout.itemSize = size
            collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    // MARK: - Internal functions
    
    internal func updateCurrentCategory(_ category: Category) {
        guard let item = categories.firstIndex(where: { $0 == category }) else {
            return
        }
        
        guard let selectedItem = collectionView.indexPathsForSelectedItems?.first?.item else {
            return
        }
        
        guard selectedItem != item else {
            return
        }
        
        (0..<categories.count).forEach {
            let indexPath = IndexPath(item: $0, section: 0)
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        let indexPath = IndexPath(item: item, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
    
    // MARK: - IBActions
    
    @IBAction private func changeKeyboard() {
        delegate?.categoriesBottomViewDidPressChangeKeyboardButton(self)
    }
    
    @IBAction private func deleteBackward() {
        delegate?.categoriesBottomViewDidPressDeleteBackwardButton(self)
    }
}

// MARK: - UICollectionViewDataSource

extension CategoriesBottomView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        cell.setEmojiCategory(categories[indexPath.item])
        return cell
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectPercentage = 0
        for touch in touches {
            touchBeganPoint = touch.location(in: self)
        }
        
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchBeganPoint = touchBeganPoint else { return }
        for touch in touches {
            let point = touch.location(in: self)
            if abs(point.x - touchBeganPoint.x) < 4 { continue }
            if let touchingIndexPath = collectionView?.indexPathForItem(at: touch.location(in: collectionView)) {
                collectionView(collectionView, didSelectItemAt: touchingIndexPath)
                if !(collectionView.indexPathsForSelectedItems?.contains(touchingIndexPath) ?? false) {
                    collectionView.indexPathsForSelectedItems?.forEach {
                        collectionView.deselectItem(at: $0, animated: true)
                    }
                    collectionView.selectItem(at: touchingIndexPath, animated: true, scrollPosition: .centeredHorizontally)
                }
                
                if let touchingCell = collectionView.cellForItem(at: touchingIndexPath) {
                    let xInTouchingCell = touch.location(in: touchingCell).x
                    let leftRightInset: CGFloat = 1
                    
                    selectPercentage = max(0, min(1, Double((xInTouchingCell - leftRightInset) / (touchingCell.bounds.maxX - 2 * leftRightInset))))
                }
                
                return
            }
        }
        super.touchesMoved(touches, with: event)
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let touchingIndexPath = collectionView?.indexPathForItem(at: touch.location(in: collectionView)) {
                collectionView(collectionView, didSelectItemAt: touchingIndexPath)
                collectionView.selectItem(at: touchingIndexPath, animated: true, scrollPosition: .centeredHorizontally)
                return
            }
        }
        collectionView.indexPathsForSelectedItems?.forEach {
            collectionView.deselectItem(at: $0, animated: true)
        }
        super.touchesEnded(touches, with: event)
    }
}

// MARK: - UICollectionViewDelegate

extension CategoriesBottomView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.categoriesBottomViewDidSelecteCategory(categories[indexPath.item], percentage: selectPercentage, bottomView: self)
    }
    
}

// MARK: - Private functions

extension CategoriesBottomView {
 
    private func selectFirstCell() {
        let indexPath = IndexPath(item: 0, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
    }
    
}
