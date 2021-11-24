
import Foundation
import UIKit

import CocoaLumberjackSwift

// Touch Begin near the screen edge is delayed by iOS.
// To workaround the issue, use UILongPressGestureRecognizer.
class BypassScreenEdgeTouchDelayGestureRecognizer: UILongPressGestureRecognizer {
    private var onTouchesBegan:((Set<UITouch>, UIEvent) -> Void)
    
    init(onTouchesBegan: @escaping ((Set<UITouch>, UIEvent) -> Void)) {
        self.onTouchesBegan = onTouchesBegan
        
        super.init(target: nil, action: nil)
        
        minimumPressDuration = 0
        cancelsTouchesInView = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        onTouchesBegan(touches, event)
    }
}

class TouchState {
    let touch: UITouch
    var activeKeyView: KeyView
    var cursorMoveStartPosition: CGPoint
    var initialAction: KeyboardAction
    var hasTakenAction: Bool

    init(touch: UITouch, cursorMoveStartPosition: CGPoint, activeKeyView: KeyView, initialAction: KeyboardAction) {
        self.touch = touch
        self.activeKeyView = activeKeyView
        self.cursorMoveStartPosition = cursorMoveStartPosition
        self.initialAction = initialAction
        hasTakenAction = false
    }
}

class TouchHandler {
    private let c = InstanceCounter<TouchHandler>()
    
    enum InputMode: Equatable {
        case typing, backspacing, nextKeyboard, cursorMoving
    }
    static let keyRepeatInitialDelay = 7 // Unit is keyRepeatInterval
    static let longPressDelay = 3
    static let keyRepeatInterval = 0.08
    static let cursorMovingStepX: CGFloat = 10
    static let initialCursorMovingThreshold = cursorMovingStepX * 1.25
    static let swipeXThreshold: CGFloat = 30
    static let capsLockDoubleTapDelay = 0.2
    
    private var touches: [UITouch: TouchState] = [:]
    private var touchQueue: [UITouch] = []
    private var lastTouchTimestamp: TimeInterval?
    private var lastTouchAction: KeyboardAction?
    
    private var _inputMode: InputMode = .typing
    private var inputMode: InputMode {
        get { _inputMode }
        set {
            if _inputMode != newValue {
                // Enable keyboard when we exit cursor moving.
                callKeyHandler(.enableKeyboard(newValue != .cursorMoving))
                if newValue == .cursorMoving { FeedbackProvider.selectionFeedback.selectionChanged() }
                
                _inputMode = newValue
            }
        }
    }
    var keyboardIdiom: LayoutIdiom
    
    private weak var keyboardView: BaseKeyboardView?
    private var keyRepeatTimer: Timer?
    private var keyRepeatCounter: Int = 0
    
    init(keyboardView: BaseKeyboardView, keyboardIdiom: LayoutIdiom) {
        self.keyboardView = keyboardView
        self.keyboardIdiom = keyboardIdiom
    }
    
    func touchBegan(_ touch: UITouch, key: KeyView, with event: UIEvent?) {
        guard key.isKeyEnabled &&
              inputMode == .typing // Ignore new touches if we are not in typing mode.
            else { return }
        
        if Settings.cached.isTapHapticFeedbackEnabled {
            FeedbackProvider.lightImpact.impactOccurred()
        }
                
        // DDLogInfo("touchBegan \(key.keyCap) \(touch) \(currentTouch?.0)")
        
        keyRepeatCounter = 0
        
        setupKeyRepeatTimer()
        // On iPhone, touching new key commits previous keys except the shift key.
        if keyboardIdiom == .phone {
            endTouches(commit: true, except: touch, exceptShiftKey: true)
        }
        
        key.keyTouchBegan(touch)
        
        let action = key.selectedAction
        beginTouch(touch, activeKeyView: key, initialAction: action)
        defer {
            lastTouchTimestamp = touch.timestamp
            lastTouchAction = action
        }
        
        FeedbackProvider.play(keyboardAction: key.selectedAction)
        switch action {
        case .backspace:
            inputMode = .backspacing
        case .keyboardType where action != .keyboardType(.emojis):
            callKeyHandler(key.selectedAction)
        case .nextKeyboard:
            guard let event = event, let touchView = touch.view else { return }
            inputMode = .nextKeyboard
            keyboardView?.delegate?.handleInputModeList(from: touchView, with: event)
        case .shift(.lowercased), .shift(.uppercased):
            if let lastTouchTimestamp = lastTouchTimestamp, let lastTouchAction = lastTouchAction,
               case .shift = lastTouchAction,
               (touch.timestamp - lastTouchTimestamp).isLess(than: Self.capsLockDoubleTapDelay) {
                // Double tap, switch to caps locked.
                callKeyHandler(.keyboardType(.alphabetic(.capsLocked)))
            } else {
                // Single tag, hold shift.
                callKeyHandler(.shiftDown)
            }
        case .shift(.capsLocked):
            touches[touch]?.initialAction = .shift(.uppercased)
            callKeyHandler(.shiftDown)
        default: () // Ignore other keys on key down.
        }
    }
    
    func touchMoved(_ touch: UITouch, key: KeyView?, with event: UIEvent?) {
        if keyRepeatTimer == nil { setupKeyRepeatTimer() }
        
        // DDLogInfo("touchMoved \(key?.keyCap ?? "nil") \(touch) \(currentTouch?.0)")
        
        guard let currentTouchState = touches[touch] else { return }
        let cursorMoveStartPosition = currentTouchState.cursorMoveStartPosition
        
        switch inputMode {
        case .backspacing:
            // Swipe left to delete word.
            let point = touch.location(in: keyboardView)
            let dX = point.x - cursorMoveStartPosition.x
            if dX < -Self.swipeXThreshold && !currentTouchState.hasTakenAction {
                cancelKeyRepeatTimer()
                currentTouchState.hasTakenAction = true
                callKeyHandler(.deleteWordSwipe)
                FeedbackProvider.mediumImpact.impactOccurred()
            }
        case .cursorMoving:
            let point = touch.location(in: keyboardView)
            var dX = point.x - cursorMoveStartPosition.x
            let isLeft = dX < 0
            dX = isLeft ? -dX : dX
            let threshold = Self.cursorMovingStepX
            while dX > threshold {
                dX -= threshold
                callKeyHandler(isLeft ? .moveCursorBackward : .moveCursorForward)
                currentTouchState.hasTakenAction = true
            }
            currentTouchState.cursorMoveStartPosition = point
            currentTouchState.cursorMoveStartPosition.x -= isLeft ? -dX : dX
        case .nextKeyboard:
            guard let event = event, let touchView = touch.view else { return }
            keyboardView?.delegate?.handleInputModeList(from: touchView, with: event)
        case .typing:
            guard let key = key else { return }
            
            // If there's an popup accepting touch, forward all events to it.
            // On iPad, forward all events to the initial key to support swipe down input.
            let initialAction = currentTouchState.initialAction
            if currentTouchState.activeKeyView.hasInputAcceptingPopup ||
                keyboardIdiom.isPad && (!initialAction.isShift && !initialAction.isKeyboardType && !initialAction.isSpace) {
                currentTouchState.activeKeyView.keyTouchMoved(touch)
                return
            }
            
            defer {
                currentTouchState.activeKeyView = key
            }
            
            // Reset key repeat long press timer if we moved to another key.
            if currentTouchState.activeKeyView != key {
                cancelKeyRepeatTimer()
                setupKeyRepeatTimer()
                currentTouchState.activeKeyView.keyTouchEnded()
                currentTouchState.activeKeyView = key
                key.keyTouchBegan(touch)
                return
            }
            
            // Ignore short swipe.
            let point = touch.location(in: keyboardView), deltaX = abs(point.x - cursorMoveStartPosition.x)
            guard deltaX >= Self.initialCursorMovingThreshold else { return }
            
            // If the user is swiping the space key, or force swiping char keys, enter cursor moving mode.
            let tapStartAction = currentTouchState.initialAction
            let isForceSwiping = touch.force >= touch.maximumPossibleForce / 2 && deltaX > Self.swipeXThreshold
            switch tapStartAction {
            case .space,
                 .character(_) where isForceSwiping:
                currentTouchState.cursorMoveStartPosition = cursorMoveStartPosition
                currentTouchState.hasTakenAction = false
                key.keyTouchEnded()
                
                endTouches(commit: false, except: touch, exceptShiftKey: false)
                inputMode = .cursorMoving
            default: ()
            }
        }
    }
    
    func touchEnded(_ touch: UITouch, key: KeyView?, with event: UIEvent?) {
        guard let currentTouchState = touches[touch] else {
            DDLogError("TouchHandler.touchEnded() BUG CHECK MISSING touch \(touch) touches \(touches)")
            // Defensive programming. Switch back to typing mode if there's a bug.
            self.inputMode = .typing
            return
        }
               
        // DDLogInfo("touchEnded \(key?.keyCap ?? "nil") \(touch) \(currentTouch?.0)")
        
        defer {
            endTouch(touch, commit: false)
            inputMode = .typing
        }
        
        cancelKeyRepeatTimer()
        
        switch inputMode {
        case .backspacing:
            if !currentTouchState.hasTakenAction { callKeyHandler(.backspace) }
        case .cursorMoving:
            callKeyHandler(.moveCursorEnded)
        case .nextKeyboard:
            guard let event = event, let touchView = touch.view else { return }
            keyboardView?.delegate?.handleInputModeList(from: touchView, with: event)
        case .typing:
            let chosenKey = currentTouchState.activeKeyView
            let chosenAction = chosenKey.selectedAction
            
            switch chosenAction {
            case .shift(.uppercased):
                if case .shift(.lowercased) = lastTouchAction {
                    callKeyHandler(.shiftRelax)
                } else {
                    callKeyHandler(.shiftUp)
                }
            case .shift(.capsLocked), .keyboardType(.alphabetic), .keyboardType(.numeric), .keyboardType(.symbolic), .keyboardType(.numSymbolic): ()
            default:
                // On iPad, on key up, it commits all previous key presses to make sure text is inserted in order.
                if case .pad = keyboardIdiom {
                    endTouchesUpTo(touch)
                }
                // We cannot use chosenAction as endTouchesUpTo() might have changed the keyboard type and hence selectedActions of KeyViews.
                // We have use the latest selectedAction of the keyView.
                callKeyHandler(currentTouchState.activeKeyView.selectedAction)
                // If the user was dragging from the shift key (not locked) to a char key, change keyboard mode back to lowercase after typing.
                let supportDrag: Bool
                switch currentTouchState.initialAction {
                case .shift, .keyboardType: supportDrag = true
                default: supportDrag = false
                }
                if supportDrag,
                   case .character = chosenAction { // FIX ME cangjie?
                    callKeyHandler(.shiftUp)
                }
            }
        }
    }
    
    private func endTouchesUpTo(_ touch: UITouch) {
        let touchIndex = touchQueue.firstIndex(of: touch) ?? 0
        touchQueue
            .prefix(upTo: touchIndex)
            .filter { !(touches[$0]?.activeKeyView.selectedAction.isShift ?? false) }
            .forEach {
                endTouch($0, commit: true)
            }
    }
    
    func touchCancelled(_ touch: UITouch, with event: UIEvent?) {
        // DDLogInfo("touchCancelled \(currentTouch?.0) \(touch)")
        
        cancelKeyRepeatTimer()
        
        endTouch(touch, commit: false)
        
        inputMode = .typing
    }
    
    private func beginTouch(_ touch: UITouch, activeKeyView: KeyView, initialAction: KeyboardAction) {
        guard !touches.keys.contains(touch) else { return }
        
        let cursorMoveStartPosition = touch.location(in: keyboardView)
        touches[touch] = TouchState(touch: touch, cursorMoveStartPosition: cursorMoveStartPosition, activeKeyView: activeKeyView, initialAction: initialAction)
        touchQueue.append(touch)
    }
    
    private func endTouch(_ touch: UITouch, commit: Bool) {
        guard let endingTouch = touches[touch] else { return }
        if commit {
            touchEnded(touch, key: endingTouch.activeKeyView, with: nil)
        } else {
            endingTouch.activeKeyView.keyTouchEnded()
        }
        _ = touches.removeValue(forKey: touch)
        if let touchIndex = touchQueue.firstIndex(of: touch) {
            touchQueue.remove(at: touchIndex)
        }
    }
    
    private func endTouches(commit: Bool, except: UITouch, exceptShiftKey: Bool) {
        let touchesToRemove: Set<UITouch> = Set(touchQueue.compactMap { touch in
            let touchState = touches[touch]
            if touch != except, let touchState = touchState {
                if !exceptShiftKey || !touchState.initialAction.isShift {
                    if commit {
                        touchEnded(touch, key: touchState.activeKeyView, with: nil)
                    } else {
                        touchState.activeKeyView.keyTouchEnded()
                    }
                    return touch
                }
            }
            return nil
        })
        
        touchQueue = touchQueue.filter { !touchesToRemove.contains($0) }
        touches = touches.filter { !touchesToRemove.contains($0.key) }
    }
    
    func cancelAllTouches() {
        touches.forEach { _, touchState in
            touchState.activeKeyView.keyTouchEnded()
        }
        touches = [:]
        touchQueue = []
        inputMode = .typing
    }
    
    private func onKeyRepeat(_ timer: Timer) {
        guard timer == self.keyRepeatTimer else { timer.invalidate(); return } // Timer was overwritten.
        keyRepeatCounter += 1
        
        // On iPad, long press is disabled if shift is being held or touch was dragged from the shift key.
        let shouldDisableLongPress = keyboardIdiom.isPad && touches.values.contains(where: { $0.initialAction.isShift })
        for touchState in touches.values {
            if touchState.initialAction == .backspace {
                guard self.inputMode == .backspacing && keyRepeatCounter > Self.keyRepeatInitialDelay else { continue }
                let action: KeyboardAction
                if keyRepeatCounter <= 20 {
                    action = .backspace
                } else {
                    action = .deleteWord
                }
                callKeyHandler(action)
                touchState.hasTakenAction = true
                FeedbackProvider.play(keyboardAction: action)
            } else if self.inputMode == .typing && keyRepeatCounter > Self.longPressDelay && !shouldDisableLongPress {
                touchState.activeKeyView.keyLongPressed(touchState.touch)
                cancelKeyRepeatTimer()
            }
        }
    }
    
    private func setupKeyRepeatTimer() {
        keyRepeatTimer?.invalidate()
        keyRepeatCounter = 0
        keyRepeatTimer = Timer.scheduledTimer(withTimeInterval: Self.keyRepeatInterval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.onKeyRepeat(timer)
        }
    }
    
    private func cancelKeyRepeatTimer() {
        keyRepeatTimer?.invalidate()
        keyRepeatTimer = nil
    }
    
    private func callKeyHandler(_ action: KeyboardAction) {
        keyboardView?.delegate?.handleKey(action)
    }
}
