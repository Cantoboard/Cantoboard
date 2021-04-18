//
//  CandidateOrganizer.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/19/21.
//

import Foundation

protocol CandidateSource: class {
    func updateCandidates(reload: Bool)
    func getNumberOfSections() -> Int
    func getCandidate(indexPath: IndexPath) -> String?
    func selectCandidate(indexPath: IndexPath) -> String?
    func getCandidateComment(indexPath: IndexPath) -> String?
    func getCandidateCount(section: Int) -> Int
}

class InputEngineCandidateSource: CandidateSource {
    private var candidatePaths:[CandidatePath] = []
    private var curRimeCandidateIndex = 0
    private var hasLoadedAllBestRimeCandidates = false
    private var hasPopulatedPrefectEnglishCandidates = false, hasPopulatedBestEnglishCandidates = false, hasPopulatedWorstEnglishCandidates = false
    private weak var inputController: InputController?

    init(inputController: InputController) {
        self.inputController = inputController
    }
    
    private func resetCandidates() {
        curRimeCandidateIndex = 0
        
        candidatePaths = []
        
        hasLoadedAllBestRimeCandidates = false
        hasPopulatedPrefectEnglishCandidates = false
        hasPopulatedBestEnglishCandidates = false
        hasPopulatedWorstEnglishCandidates = false
    }
    
    private func populateCandidates() {
        guard let inputController = inputController else { return }
        let inputEngine = inputController.inputEngine
        
        guard let rimeComposingText = inputEngine.rimeComposition?.text else { return }
        let isReverseLookupMode = inputEngine.reverseLookupSchemaId != nil
        let isInRimeOnlyMode = inputEngine.isForcingRimeMode || isReverseLookupMode
        let isEnglishActive = Settings.cached.lastInputMode != .chinese && !isInRimeOnlyMode
        let englishCandidates = inputEngine.englishCandidates
        
        // If input is an English word, insert best English candidates first.
        if !hasPopulatedPrefectEnglishCandidates && isEnglishActive {
            for i in 0..<inputEngine.englishPrefectCandidatesStartIndex {
                candidatePaths.append(CandidatePath(source: .english, index: i))
            }
            hasPopulatedPrefectEnglishCandidates = true
        }
        
        // Populate the best Rime candidates. It's in the best candidates set if the user input is the prefix of candidate's composition.
        while Settings.cached.lastInputMode != .english && !hasLoadedAllBestRimeCandidates && curRimeCandidateIndex < inputEngine.rimeLoadedCandidatesCount {
            guard let candidate = inputEngine.getRimeCandidate(curRimeCandidateIndex),
                  let comment = inputEngine.getRimeCandidateComment(curRimeCandidateIndex) else {
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            let composingTextWithOnlySyllables = rimeComposingText.filter { $0.isEnglishLetter }.lowercased()
            let commentWithOnlySyllables = comment.filter { $0.isEnglishLetter }.lowercased()
            // Rime doesn't return comment if the candidate's an exact match. If commentWithOnlySyllables's empty, treat it as a hit.
            if !commentWithOnlySyllables.isEmpty && !commentWithOnlySyllables.starts(with: composingTextWithOnlySyllables) &&
                candidate.count < composingTextWithOnlySyllables.count { // 聲母輸入 case
                hasLoadedAllBestRimeCandidates = true
                break
            }
            
            addCurrentRimeCandidate(candidate)
        }
        
        // Do not populate remaining English candidates until all best Rime candidates are populated.
        if !hasLoadedAllBestRimeCandidates && inputController.inputMode != .english && !inputEngine.hasRimeLoadedAllCandidates { return }
        
        // If input is not an English word, insert best English candidates after populating Rime best candidates.
        if !hasPopulatedBestEnglishCandidates && isEnglishActive {
            for i in inputEngine.englishPrefectCandidatesStartIndex..<inputEngine.englishWorstCandidatesStartIndex {
                candidatePaths.append(CandidatePath(source: .english, index: i))
            }
            hasPopulatedBestEnglishCandidates = true
        }
        
        // Populate remaining Rime candidates.
        while Settings.cached.lastInputMode != .english && curRimeCandidateIndex < inputEngine.rimeLoadedCandidatesCount {
            guard let candidate = inputEngine.getRimeCandidate(curRimeCandidateIndex) else { continue }
            addCurrentRimeCandidate(candidate)
        }
        
        // Populate worst English candidates.
        if (inputController.inputMode == .english || inputEngine.hasRimeLoadedAllCandidates) && !hasPopulatedWorstEnglishCandidates && isEnglishActive {
            for i in inputEngine.englishWorstCandidatesStartIndex..<englishCandidates.count {
                candidatePaths.append(CandidatePath(source: .english, index: i))
            }
            hasPopulatedWorstEnglishCandidates = true
        }
    }
    
    private func addCandidate(_ candidateText: String, source: CandidatePath.Source, index: Int) {
        candidatePaths.append(CandidatePath(source: source, index: index))
    }
    
    private func addCurrentRimeCandidate(_ candidateText: String) {
        addCandidate(candidateText, source: .rime, index: curRimeCandidateIndex)
        curRimeCandidateIndex += 1
    }
    
    func updateCandidates(reload: Bool) {
        guard let inputEngine = inputController?.inputEngine else { return }
        if reload { resetCandidates() }
        
        if inputController?.inputEngine.rimeLoadedCandidatesCount == 0 || !reload { _ = inputEngine.loadMoreRimeCandidates() }
        populateCandidates()
    }

    func getNumberOfSections() -> Int {
        return 1
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 && indexPath.row < candidatePaths.count else { return nil }
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return nil }
        
        switch candidatePath.source {
        case .rime: return inputController?.inputEngine.getRimeCandidate(candidatePath.index)
        case .english: return inputController?.inputEngine.englishCandidates[safe: candidatePath.index]
        }
    }
    
    private func getCandidatePath(indexPath: IndexPath) -> CandidatePath? {
        return candidatePaths[safe: indexPath.row]
    }
    
    func selectCandidate(indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 && indexPath.row < candidatePaths.count else { return nil }
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return nil }
        
        switch candidatePath.source {
        case .rime: return inputController?.inputEngine.selectRimeCandidate(candidatePath.index)
        case .english: return inputController?.inputEngine.selectEnglishCandidate(candidatePath.index)
        }
    }
    
    func getCandidateComment(indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 && indexPath.row < candidatePaths.count else { return nil }
        guard let candidatePath = getCandidatePath(indexPath: indexPath) else { return nil }
        
        switch candidatePath.source {
        case .rime: return inputController?.inputEngine.getRimeCandidateComment(candidatePath.index)
        default: return nil
        }
    }
    
    func getCandidateCount(section: Int) -> Int {
        guard section == 0 else { return 0 }
        
        return candidatePaths.count
    }
}

class AutoSuggestionCandidateSource: CandidateSource {
    private let candidates: [String]
    
    init(_ candidates: [String]) {
        self.candidates = candidates
    }
    
    func updateCandidates(reload: Bool) {
    }
    
    func getNumberOfSections() -> Int {
        return 1
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 else { return nil }
        return candidates[safe: indexPath.row]
    }
    
    func selectCandidate(indexPath: IndexPath) -> String? {
        return getCandidate(indexPath: indexPath)
    }
    
    func getCandidateComment(indexPath: IndexPath) -> String? {
        return nil
    }
    
    func getCandidateCount(section: Int) -> Int {
        return candidates.count
    }
}

struct CandidatePath {
    enum Source {
        case english, rime
    }
    let source: Source
    let index: Int
}

enum AutoSuggestionType {
    case halfWidthPunctuation
    case fullWidthPunctuation
    case halfWidthDigit
    case fullWidthArabicDigit
    case fullWidthLowerDigit
    case fullWidthUpperDigit
}

// This class filter, group by and sort the candidates.
class CandidateOrganizer {
    private static let halfWidthPunctuationCandidateSource = AutoSuggestionCandidateSource([".", ",", "?", "!", "。", "，", "？", "！"])
    private static let fullWidthPunctuationCandidateSource = AutoSuggestionCandidateSource(["。", "，", "？", "！", ".", ",", "?", "!"])
    private static let halfWidthDigitCandidateSource = AutoSuggestionCandidateSource(["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
    private static let fullWidthArabicDigitCandidateSource = AutoSuggestionCandidateSource(["０", "１", "２", "３", "４", "５", "６", "７", "８", "９"])
    private static let fullWidthLowerDigitCandidateSource = AutoSuggestionCandidateSource(["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "零", "廿", "百", "千", "萬", "億"])
    private static let fullWidthUpperDigitCandidateSource = AutoSuggestionCandidateSource(["零", "壹", "貳", "叄", "肆", "伍", "陸", "柒", "捌", "玖", "拾", "佰", "仟", "萬", "億"])
    
    enum GroupBy {
        case frequency, radical, stroke, tone
    }
    
    var onMoreCandidatesLoaded: ((CandidateOrganizer) -> Void)?
    var onReloadCandidates: ((CandidateOrganizer) -> Void)?
    var candidateSource: CandidateSource?
    var autoSuggestionType: AutoSuggestionType?
    
    weak var inputController: InputController?
    
    init(inputController: InputController) {
        self.inputController = inputController
    }
    
    func requestMoreCandidates(section: Int) {
        guard section == 0 else { return }
        updateCandidates(reload: false)
    }
    
    /*var groupBy: GroupBy = .frequency {
        didSet {
            
        }
    }*/
    
    func updateCandidates(reload: Bool) {
        if let inputController = inputController,
           inputController.inputEngine.isComposing {
            candidateSource = InputEngineCandidateSource(inputController: inputController)
        } else if let autoSuggestionType = autoSuggestionType {
            switch autoSuggestionType {
            case .fullWidthArabicDigit: candidateSource = Self.fullWidthArabicDigitCandidateSource
            case .fullWidthLowerDigit: candidateSource = Self.fullWidthLowerDigitCandidateSource
            case .fullWidthPunctuation: candidateSource = Self.fullWidthPunctuationCandidateSource
            case .fullWidthUpperDigit: candidateSource = Self.fullWidthUpperDigitCandidateSource
            case .halfWidthDigit: candidateSource = Self.halfWidthDigitCandidateSource
            case .halfWidthPunctuation: candidateSource = Self.halfWidthPunctuationCandidateSource
            }
        } else {
            candidateSource = nil
        }
        
        candidateSource?.updateCandidates(reload: reload)
        
        if reload {
            onReloadCandidates?(self)
        } else {
            onMoreCandidatesLoaded?(self)
        }
    }

    func getNumberOfSections() -> Int {
        return candidateSource?.getNumberOfSections() ?? 0
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        return candidateSource?.getCandidate(indexPath: indexPath)
    }
    
    func selectCandidate(indexPath: IndexPath) -> String? {
        return candidateSource?.selectCandidate(indexPath: indexPath)
    }
    
    func getCandidateComment(indexPath: IndexPath) -> String? {
        return candidateSource?.getCandidateComment(indexPath: indexPath)
    }
    
    func getCandidateCount(section: Int) -> Int {
        return candidateSource?.getCandidateCount(section: section) ?? 0
    }
    
    var shouldCloseCandidatePaneOnCommit: Bool {
        candidateSource === Self.fullWidthArabicDigitCandidateSource ||
        candidateSource === Self.fullWidthLowerDigitCandidateSource ||
        candidateSource === Self.fullWidthUpperDigitCandidateSource ||
        candidateSource === Self.halfWidthDigitCandidateSource
    }
}
