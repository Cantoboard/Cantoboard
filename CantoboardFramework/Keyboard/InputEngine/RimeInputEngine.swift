//
//  RimeEngine.swift
//  Stockboard
//
//  Created by Alex Man on 1/12/21.
//

import Foundation
import UIKit

class RimeInputEngine: NSObject, InputEngine {
    private weak var rimeSession: RimeSession?
    private var candidates = NSMutableArray(), comments = NSMutableArray()
        
    override init() {
        super.init()
        tryCreateRimeSessionIfNeeded()
    }
    
    deinit {
        guard let rimeSession = rimeSession else { return }
        RimeApi.shared.close(rimeSession)
    }
    
    func processChar(_ char: Character) -> Bool {
        if let asciiValue = char.asciiValue {
            processKey(Int32(asciiValue))
            return true
        }
        // Ignore non letter .
        return false
    }
    
    func processBackspace() -> Bool {
        guard composition?.caretIndex ?? 0 > 0 else { return false }
        processKey(0xff08)
        return true
    }
    
    private func getComposedText(append: Character) -> String {
        var text = composition?.text ?? ""
        text.append(append)
        return text
    }
    
    private func processKey(_ keycode: Int32, _ modifier: Int32 = 0) {
        tryCreateRimeSessionIfNeeded()

        guard let rimeSession = rimeSession else {
            NSLog("processKey RimeSession is nil.")
            return
        }
        
        rimeSession.processKey(keycode, modifier: modifier)
        refreshCandidates()
    }
    
    private func refreshCandidates() {
        candidates = NSMutableArray()
        comments = NSMutableArray()
        // _ = requestMoreCandidates()
    }
        
    func moveCaret(offset: Int) -> Bool {
        guard abs(offset) == 1 else {
            NSLog("moveCaret offset=\(offset) not supproted.")
            return false
        }
        
        guard let rimeSession = rimeSession else {
            NSLog("moveCaret RimeSession is nil.")
            return false
        }
        
        guard let preedit = rimeSession.compositionText else {
            NSLog("moveCaret() is called while compositionText is nil.")
            return false
        }
        
        let isMovingLeft = offset < 0
        if isMovingLeft {
            guard rimeSession.compositionCaretBytePosition > 0 else { return false }
        } else {
            guard rimeSession.compositionCaretBytePosition < preedit.utf8.count else { return false }
        }
        
        processKey(isMovingLeft ? 0xff96 : 0xff98)
        return true
    }
    
    func clearInput() {
        guard let rimeSession = self.rimeSession else { return }
        rimeSession.processKey(0xff1b, modifier: 0)
        processKey(0xff1b)
    }
    
    func getCandidates() -> NSArray {
        return candidates
    }
    
    func getCandidate(_ index: Int) -> String? {
        return candidates[index] as? String
    }
    
    func getComment(_ index: Int) -> String? {
        return comments[index] as? String
    }
    
    // Return true if it has loaded more candidates
    func loadMoreCandidates() -> Bool {
        guard let rimeSession = rimeSession else {
            NSLog("loadMoreCandidates RimeSession is nil.")
            return false
        }
        return rimeSession.getCandidates(candidates, comments: comments)
    }
    
    func selectCandidate(_ index: Int) -> String? {
        guard let rimeSession = rimeSession else {
            NSLog("selectCandidate RimeSession is nil.")
            return nil
        }
        
        guard index < candidates.count else {
            NSLog("Bad index: %d. Count: %d", index, candidates.count)
            return nil
        }
        
        rimeSession.selectCandidate(Int32(index))
        refreshCandidates()
        return rimeSession.getCommitedText()
    }
    
    var composition: Composition? {
        get {
            guard let rimeSession = rimeSession else { return nil }
            guard let text = rimeSession.compositionText else { return nil }
            if text.count == 0 { return nil }
            let caretByteIndex = Int(rimeSession.compositionCaretBytePosition)
            let caretCharIndex = convertUtf8ByteIndexToCharIndex(text, caretByteIndex)
            return Composition(text: text, caretIndex: Int(caretCharIndex))
        }
    }
    
    private func convertUtf8ByteIndexToCharIndex(_ text: String, _ byteIndex: Int) -> Int {
        let textUtf8 = text.utf8
        let utf8ByteIndex = textUtf8.index(textUtf8.startIndex, offsetBy: byteIndex)
        let charIndex = text.distance(from: textUtf8.startIndex, to: utf8ByteIndex)
        return charIndex
    }
    
    private func tryCreateRimeSessionIfNeeded() {
        if rimeSession == nil && RimeApi.shared.state == .succeeded {
            createRimeSession()
        } else {
            RimeApi.stateChangeCallbacks.append({ [weak self] rimeApi, newState in
                guard let self = self, self.rimeSession == nil else { return true }
                self.tryCreateRimeSessionIfNeededAsyncWithRetry(delay: 1/30, retryCount: 0)
                return newState == .succeeded || newState == .failure
            })
        }
    }
    
    private func tryCreateRimeSessionIfNeededAsyncWithRetry(delay: Double, retryCount: Int) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay, execute: {
            if self.rimeSession == nil {
                self.createRimeSession()
                if let rimeSession = self.rimeSession {
                    NSLog("Created RimeSession \(rimeSession) in callback.")
                } else {
                    if retryCount < 10 {
                        NSLog("Retrying to create rime session.")
                        self.tryCreateRimeSessionIfNeededAsyncWithRetry(delay: delay * 1.1, retryCount: retryCount + 1)
                    } else {
                        NSLog("Gave up creating rime session after \(retryCount) attempts.")
                    }
                }
            }
        })
    }
    
    private func createRimeSession() {
        rimeSession = RimeApi.shared.createSession()
        refreshChineseScript()
    }
    
    func refreshChineseScript() {
        rimeSession?.setOption("simplification", value: Settings.shared.chineseScript == .simplified)
        refreshCandidates()
    }
}

class RimeApiListener: NSObject, RimeNotificationHandler {
    // Return true to unregister the block.
    typealias StateChangeBlock = (_ rimeApi: RimeApi, _ newState: RimeApiState) -> Bool
    
    var stateChangeCallbacks: [StateChangeBlock] = []
    
    func onStateChange(_ rimeApi: RimeApi, newState: RimeApiState) {
        switch newState {
        case .deploying:
            let version = rimeApi.getVersion() ?? "version unknown"
            NSLog("Rime \(version) is starting...")
        case .succeeded: NSLog("Rime started.")
        case .failure: NSLog("Rime failed to start.")
        case .uninitialized: NSLog("Rime deinitialized.")
        @unknown default: NSLog("Unknown rime state \(newState).")
        }
        
        stateChangeCallbacks.removeAll(where: { $0(rimeApi, newState) })
    }
    
    func onNotification(_ messageType: String!, messageValue: String!) {
        NSLog("Rime notification \(messageType!) \(messageValue!).")
    }
}
