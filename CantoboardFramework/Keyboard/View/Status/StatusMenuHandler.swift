//
//  StatusMenuHandler.swift
//  CantoboardFramework
//
//  Created by Alex Man on 6/15/21.
//

import Foundation
import UIKit

protocol StatusMenuHandler: AnyObject {
    var delegate: KeyboardViewDelegate? { get set }
    var state: KeyboardState { get set }
    var statusMenu: StatusMenu? { get set }
    var statusMenuOriginY: CGFloat { get }
    var keyboardSize: CGSize { get }

    func layoutStatusMenu()
    func handleStatusMenu(from: UIView, with: UIEvent?) -> Bool
    func showStatusMenu()
    func hideStatusMenu()
}

extension StatusMenuHandler where Self: BaseKeyboardView {
    func layoutStatusMenu() {
        guard let statusMenu = statusMenu else { return }
        
        let size = statusMenuSize
        let origin = CGPoint(x: frame.width - size.width, y: statusMenuOriginY)
        let frame = CGRect(origin: origin, size: size)
        statusMenu.frame = frame.offsetBy(dx: -StatusMenu.xInset, dy: 0)
    }
    
    private var statusMenuSize: CGSize {
        let rowHeight = layoutConstants.ref.statusMenuItemHeight
        
        let height = rowHeight * CGFloat(statusMenu?.itemLabelInRows.count ?? 0)
        let width = layoutConstants.ref.statusMenuWidth
        return CGSize(width: width, height: height)
    }
    
    func handleStatusMenu(from: UIView, with: UIEvent?) -> Bool {
        if let touch = with?.allTouches?.first, touch.view == from {
            switch touch.phase {
            case .began, .moved, .stationary:
                showStatusMenu()
                statusMenu?.touchesMoved([touch], with: with)
                return true
            case .ended:
                statusMenu?.touchesEnded([touch], with: with)
                hideStatusMenu()
                return false
            case .cancelled:
                statusMenu?.touchesCancelled([touch], with: with)
                hideStatusMenu()
                return false
            default: ()
            }
        } else {
            hideStatusMenu()
            return false
        }
        return statusMenu != nil
    }
    
    func showStatusMenu() {
        guard statusMenu == nil else { return }
        FeedbackProvider.softImpact.impactOccurred()
        
        let menuRows: [[KeyCap]] = state.keyboardIdiom == .phone && layoutConstants.ref.isPortrait ? [
            [ .changeSchema(.jyutping), .toggleInputMode(.english, nil, false) ],
            [ .changeSchema(.yale), .changeSchema(.jyutping10keys) ],
            [ .changeSchema(Settings.cached.cangjieVersion.toRimeSchema), .changeSchema(.quick) ],
            [ .changeSchema(.stroke), .changeSchema(.mandarin) ],
        ] : [
            [ .changeSchema(.yale), .changeSchema(.jyutping), .changeSchema(.jyutping10keys), .toggleInputMode(.english, nil, false) ],
            [ .changeSchema(Settings.cached.cangjieVersion.toRimeSchema), .changeSchema(.quick), .changeSchema(.stroke), .changeSchema(.mandarin) ],
        ]
        
        let statusMenu = StatusMenu(menuRows: menuRows)
        statusMenu.handleKey = delegate?.handleKey

        addSubview(statusMenu)
        self.statusMenu = statusMenu
    }
    
    func hideStatusMenu() {
        statusMenu?.removeFromSuperview()
    }
}
