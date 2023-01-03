//
//  RimeEngine.swift
//  Stockboard
//
//  Created by Alex Man on 1/12/21.
//

import Foundation
import UIKit

import CocoaLumberjackSwift

public enum RimeSchema: String, Codable {
    case jyutping = "jyut6ping3"
    case yale = "yale"
    case cangjie3 = "cangjie3"
    case cangjie5 = "cangjie5"
    case quick = "quick5"
    case mandarin = "luna_pinyin"
    case stroke = "stroke"
    case loengfan = "loengfan"
    case jyutping10keys = "jyut6ping3_10keys"
    
    var signChar: String {
        switch self {
        case .cangjie3, .cangjie5: return "倉"
        case .yale: return "耶"
        case .quick: return "速"
        case .jyutping: return "粵"
        case .loengfan: return "兩"
        case .mandarin: return "普"
        case .stroke: return "筆"
        case .jyutping10keys: return "粵"
        }
    }
    
    var shortName: String {
        switch self {
        case .cangjie3, .cangjie5: return "倉頡"
        case .yale: return "耶魯"
        case .quick: return "速成"
        case .jyutping: return "粵拼"
        case .loengfan: return "兩分"
        case .mandarin: return "普拼"
        case .stroke: return "筆劃"
        case .jyutping10keys: return "粵格"
        }
    }
    
    var isKeypadBased: Bool {
        switch self {
        case .stroke, .jyutping10keys: return true
        default: return false
        }
    }
    
    var is10Keys: Bool {
        switch self {
        case .jyutping10keys: return true
        default: return false
        }
    }
    
    var isCangjieFamily: Bool {
        self == .cangjie3 || self == .cangjie5 || self == .quick
    }
    
    var isShapeBased: Bool {
        self == .cangjie3 || self == .cangjie5 || self == .quick || self == .stroke
    }
    
    var isCantonese: Bool {
        switch self {
        case .jyutping, .yale, .jyutping10keys: return true
        default: return false
        }
    }
    
    var supportCantoneseTonalInput: Bool {
        switch self {
        case .jyutping, .yale: return true
        default: return false
        }
    }
    
    var supportMixedMode: Bool {
        switch self {
        case .stroke, .jyutping10keys: return false
        default: return true
        }
    }
}

class RimeInputEngine: NSObject, InputEngine {
    private weak var rimeSession: RimeSession?
    private(set) var hasLoadedAllCandidates = false
    
    var schema: RimeSchema {
        didSet {
            guard oldValue != schema else { return }
            DDLogInfo("Switching scheam of session \(rimeSession?.debugDescription ?? "") from \(oldValue) to \(schema)")
            setCurrentSchema(schema)
            refreshCharForm()
        }
    }
    
    var charForm: CharForm = SessionState.main.lastCharForm {
        didSet {
            guard oldValue != charForm else { return }
            setCharForm(isSimplification: charForm == .simplified)
        }
    }
    
    init(schema: RimeSchema) {
        self.schema = schema
        super.init()
    }
    
    deinit {
        guard let rimeSession = rimeSession else { return }
        RimeApi.shared.close(rimeSession)
    }
    
    func processChar(_ char: Character) -> Bool {
        let char = schema != .jyutping10keys ? char.lowercasedChar : char
        if rawInput?.text.last == "'" && char == "'" { return true }
        if let asciiValue = char.asciiValue {
            processKey(Int32(asciiValue))
            return true
        }
        // Ignore non letter .
        return false
    }
    
    func processBackspace() -> Bool {
        guard composition?.caretIndex ?? 0 > 0 else { return false }
        rimeSession?.processKey(0xff08, modifier: 0)// Backspace
        rimeSession?.setCandidateMenuToFirstPage()
        refreshCandidates()
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
            DDLogInfo("processKey RimeSession is nil.")
            return
        }
        
        rimeSession.processKey(keycode, modifier: modifier)
        refreshCandidates()
    }
    
    private func refreshCandidates() {
        hasLoadedAllCandidates = false
        rimeSession?.setCandidateMenuToFirstPage()
    }
        
    func moveCaret(offset: Int) -> Bool {
        guard abs(offset) == 1 else {
            DDLogInfo("moveCaret offset=\(offset) not supproted.")
            return false
        }
        
        guard let rimeSession = rimeSession else {
            DDLogInfo("moveCaret RimeSession is nil.")
            return false
        }
        
        guard let preedit = rimeSession.compositionText else {
            DDLogInfo("moveCaret() is called while compositionText is nil.")
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
        rimeSession.processKey(0xff1b, modifier: 0) // Esc
        processKey(0xff1b)
    }
    
    func getCandidate(_ index: Int) -> String? {
        return rimeSession?.getCandidate(UInt32(index))
    }
    
    func getCandidateComment(_ index: Int) -> String? {
        return rimeSession?.getComment(UInt32(index))
    }
    
    // Return false if it loaded all candidates
    func loadMoreCandidates() -> Bool {
        guard let rimeSession = rimeSession else {
            DDLogInfo("loadMoreCandidates RimeSession is nil.")
            hasLoadedAllCandidates = true
            return false
        }
        let hasRemainingCandidates = rimeSession.loadMoreCandidates()
        hasLoadedAllCandidates = !hasRemainingCandidates
        return hasRemainingCandidates
    }
    
    var loadedCandidatesCount: Int {
        Int(rimeSession?.getLoadedCandidatesCount() ?? 0)
    }
    
    func selectCandidate(_ index: Int) -> String? {
        guard let rimeSession = rimeSession else {
            DDLogInfo("selectCandidate RimeSession is nil.")
            return nil
        }
        
        if !rimeSession.selectCandidate(Int32(index)) {
            DDLogInfo("Bad index: \(index). Count: \(rimeSession.getLoadedCandidatesCount())")
            return nil
        }
        refreshCandidates()
        return rimeSession.getCommitedText()
    }
    
    func unlearnCandidate(_ index: Int) -> Bool {
        guard let rimeSession = rimeSession else {
            DDLogInfo("unlearnCandidate RimeSession is nil.")
            return false
        }
        let deleted = rimeSession.unlearnCandidate(index)
        refreshCandidates()
        return deleted
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
    
    var rawInput: Composition? {
        get {
            guard let rimeSession = rimeSession else { return nil }
            guard let text = rimeSession.rawInput else { return nil }
            if text.count == 0 { return nil }
            let caretByteIndex = Int(rimeSession.rawInputCaretBytePosition)
            let caretCharIndex = convertUtf8ByteIndexToCharIndex(text, caretByteIndex)
            return Composition(text: text, caretIndex: Int(caretCharIndex))
        }
    }
    
    var isFirstCandidateCompleteMatch: Bool {
        rimeSession?.isFirstCandidateCompleteMatch ?? false
    }
    
    var userSelectedTextLength: Int {
        return rimeSession?.userSelectedTextLength ?? 0
    }
    
    func setInput(_ composition: Composition) {
        rimeSession?.setInput(composition.text)
        rimeSession?.setCaretPos(composition.caretIndex)
        refreshCandidates()
    }
    
    private func convertUtf8ByteIndexToCharIndex(_ text: String, _ byteIndex: Int) -> Int {
        let textUtf8 = text.utf8
        let utf8ByteIndex = textUtf8.index(textUtf8.startIndex, offsetBy: byteIndex)
        let charIndex = text.distance(from: textUtf8.startIndex, to: utf8ByteIndex)
        return charIndex
    }
    
    func tryCreateRimeSessionIfNeeded() {
        if rimeSession == nil && RimeApi.shared.state == .succeeded {
            self.createRimeSession()
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
                    DDLogInfo("Created RimeSession \(rimeSession) in callback.")
                    // exit(0)
                } else {
                    if retryCount < 10 {
                        DDLogInfo("Retrying to create rime session.")
                        self.tryCreateRimeSessionIfNeededAsyncWithRetry(delay: delay * 1.1, retryCount: retryCount + 1)
                    } else {
                        DDLogInfo("Gave up creating rime session after \(retryCount) attempts.")
                    }
                }
            }
        })
    }
    
    private func createRimeSession() {
        rimeSession = RimeApi.shared.createSession()
        setCurrentSchema(schema)
        refreshCharForm()
    }
    
    private func setCurrentSchema(_ schemaId: RimeSchema) {
        var rimeSchemaId = schemaId.rawValue
        if schemaId.supportCantoneseTonalInput && Settings.cached.toneInputMode == .vxq {
            rimeSchemaId += "vxq"
        }
        rimeSession?.setCurrentSchema(rimeSchemaId)
    }
    
    private func refreshCharForm() {
        setCharForm(isSimplification: charForm == .simplified)
    }
    
    private func setCharForm(isSimplification: Bool) {
        rimeSession?.setOption("variants_hk", value: !isSimplification && Settings.cached.enableHKCorrection)
        rimeSession?.setOption("simp_hk2s", value: isSimplification)
        rimeSession?.setOption("simplification", value: isSimplification)
        rimeSession?.setCandidateMenuToFirstPage()
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
            let version = rimeApi.version() ?? "version unknown"
            DDLogInfo("Rime \(version) is starting...")
        case .succeeded: DDLogInfo("Rime started.")
        case .failure: DDLogInfo("Rime failed to start.")
        case .uninitialized: DDLogInfo("Rime deinitialized.")
        @unknown default: DDLogInfo("Unknown rime state \(newState).")
        }
        
        stateChangeCallbacks.removeAll(where: { $0(rimeApi, newState) })
    }
    
    func onNotification(_ messageType: String!, messageValue: String!) {
        DDLogInfo("Rime notification \(messageType!) \(messageValue!).")
    }
}
