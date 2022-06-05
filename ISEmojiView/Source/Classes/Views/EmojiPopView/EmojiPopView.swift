//
//  EmojiPopView.swift
//  ISEmojiView
//
//  Created by Beniamin Sarkisyan on 01/08/2018.
//

import Foundation

internal protocol EmojiPopViewDelegate: AnyObject {
    
    /// called when the popView needs to dismiss itself
    func emojiPopViewShouldDismiss(emojiPopView: EmojiPopView)
    
}

internal class EmojiPopView: UIView {
    
    // MARK: - Internal variables
    
    /// the delegate for callback
    internal weak var delegate: EmojiPopViewDelegate?
    
    internal var currentEmoji: String = ""
    internal var emojiArray: [String] = []
    
    internal var constants: Constants = PhoneConstants()
    
    // MARK: - Private variables
    
    private var locationX: CGFloat = 0.0
    
    private var emojiButtons: [UIButton] = []
    private var emojisView: UIView = UIView()
    
    private var emojisX: CGFloat = 0.0
    private var emojisWidth: CGFloat = 0.0
    
    private var showBottomPart: Bool = true
    
    // MARK: - Init functions
    
    init(constants: Constants) {
        self.constants = constants
        let emojiPopViewSize = constants.emojiPopViewSize
        super.init(frame: CGRect(x: 0, y: 0, width: emojiPopViewSize.width, height: emojiPopViewSize.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Override functions
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let result = point.x >= emojisX && point.x <= emojisX + emojisWidth && point.y >= 0 && point.y <= constants.topPartSize.height
        
        if !result {
            dismiss()
        }
        
        return result
    }
    
    // MARK: - Internal functions
    
    internal func move(location: CGPoint, showBottomPart: Bool, animation: Bool = true) {
        self.showBottomPart = showBottomPart
        let deltaX = frame.origin.x - location.x
        let deltaY = frame.origin.y - location.y
        guard abs(deltaX) > 1e-5 || abs(deltaY) > 1e-5 else { return }
        
        locationX = location.x
        setupUI()
        
        UIView.animate(withDuration: animation ? 0.08 : 0, animations: {
            self.alpha = 1
            self.frame = CGRect(x: location.x, y: location.y, width: self.frame.width, height: self.frame.height)
        }, completion: { complate in
            self.isHidden = false
        })
    }
    
    internal func dismiss() {
        UIView.animate(withDuration: 0.08, animations: {
            self.alpha = 0
        }, completion: { complate in
            self.isHidden = true
        })
    }
    
    internal func setEmoji(_ emoji: Emoji) {
        self.currentEmoji = emoji.emoji
        self.emojiArray = emoji.emojis
    }
    
}

// MARK: - Private functions

extension EmojiPopView {
    
    private func createEmojiButton(_ emoji: String) -> UIButton {
        let button = UIButton(type: .custom)
        let emojiFont = constants.emojiFont
        let emojiSize = constants.emojiSize
        button.titleLabel?.font = emojiFont
        button.setTitle(emoji, for: .normal)
        button.frame = CGRect(x: CGFloat(emojiButtons.count) * emojiSize.width, y: 0, width: emojiSize.width, height: emojiSize.height)
        button.addTarget(self, action: #selector(selectEmojiType(_:)), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }
    
    @objc private func selectEmojiType(_ sender: UIButton) {
        if let selectedEmoji = sender.titleLabel?.text {
            currentEmoji = selectedEmoji
            delegate?.emojiPopViewShouldDismiss(emojiPopView: self)
        }
    }
    
    private func setupUI() {
        isHidden = true
        
        self.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        let emojiSize = constants.emojiSize
        let topPartSize = constants.topPartSize
        let bottomPartSize = constants.bottomPartSize
        // adjust location of emoji bar if it is off the screen
        emojisWidth = topPartSize.width + emojiSize.width * CGFloat(emojiArray.count - 1)
        emojisX = 0.0 // the x adjustment within the popView to account for the shift in location
        let screenWidth = UIScreen.main.bounds.width
        if emojisWidth + locationX > screenWidth {
            emojisX = -CGFloat(emojisWidth + locationX - screenWidth + 8) // 8 for padding to border
        }
        // readjust in case someone is long-pressing right at the edge of the screen
        let halfWidth = topPartSize.width / 2.0 - bottomPartSize.width / 2.0
        if emojisX + emojisWidth < halfWidth + bottomPartSize.width {
            emojisX += (halfWidth + bottomPartSize.width) - (emojisX + emojisWidth)
        }
        
        // path
        let path = maskPath()
        
        // border
        let borderLayer = CAShapeLayer()
        borderLayer.path = path
        borderLayer.strokeColor = UIColor(white: 0.8, alpha: 1).cgColor
        borderLayer.fillColor = UIColor.white.cgColor
        borderLayer.lineWidth = 1
        layer.addSublayer(borderLayer)
        
        // mask
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        
        // content layer
        let contentLayer = CALayer()
        contentLayer.frame = bounds
        contentLayer.backgroundColor = UIColor.white.cgColor
        contentLayer.mask = maskLayer
        layer.addSublayer(contentLayer)
        
        emojisView.removeFromSuperview()
        emojisView = UIView(frame: CGRect(x: emojisX + 8, y: 10, width: CGFloat(emojiArray.count) * emojiSize.width, height: emojiSize.height))
        
        // add buttons
        emojiButtons = []
        for emoji in emojiArray {
            let button = createEmojiButton(emoji)
            emojiButtons.append(button)
            emojisView.addSubview(button)
        }
        
        addSubview(emojisView)
    }
    
    func maskPath() -> CGMutablePath {
        let path = CGMutablePath()
        let topPartSize = constants.topPartSize
        let bottomPartSize = constants.bottomPartSize
        
        path.addRoundedRect(
                 in: CGRect(
                     x: emojisX,
                     y: 0.0,
                     width: emojisWidth,
                     height: topPartSize.height
                 ),
                 cornerWidth: 10,
                 cornerHeight: 10
             )

        if showBottomPart {
            path.addRoundedRect(
                in: CGRect(
                    x: topPartSize.width / 2.0 - bottomPartSize.width / 2.0,
                    y: topPartSize.height - 10,
                    width: bottomPartSize.width,
                    height: bottomPartSize.height + 10
                ),
                cornerWidth: 5,
                cornerHeight: 5
            )
        }
        
        return path
    }
}
