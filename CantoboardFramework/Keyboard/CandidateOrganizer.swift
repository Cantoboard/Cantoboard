//
//  CandidateOrganizer.swift
//  CantoboardFramework
//
//  Created by Alex Man on 3/19/21.
//

import Foundation

protocol CandidateSource: class {
    var candidates: NSArray { get }
    var requestMoreCandidate: () -> Bool { get }
    var getCandidateSource: (Int) -> CandidatePath.Source? { get }
}

class InputEngineCandidateSource: CandidateSource {
    let candidates: NSArray
    let requestMoreCandidate: () -> Bool
    let getCandidateSource: (Int) -> CandidatePath.Source?
    
    init(candidates: NSArray, requestMoreCandidate: @escaping () -> Bool, getCandidateSource: @escaping (Int) -> CandidatePath.Source?) {
        self.candidates = candidates
        self.requestMoreCandidate = requestMoreCandidate
        self.getCandidateSource = getCandidateSource
    }
}

class AutoSuggestionCandidateSource: CandidateSource {
    let candidates: NSArray
    let requestMoreCandidate: () -> Bool
    let getCandidateSource: (Int) -> CandidatePath.Source?
    
    init(_ candidates: [String]) {
        self.candidates = NSArray(array: candidates)
        requestMoreCandidate = { false }
        getCandidateSource = { _ in nil }
    }
}

// This class filter, group by and sort the candidates.
class CandidateOrganizer {
    enum GroupBy {
        case frequency, radical, stroke, tone
    }
    
    var filter: CandidateFilter = .mixed {
        didSet {
            loadMoreCandidates(reset: true)
            DispatchQueue.main.async {
                var settings = Settings.cached
                settings.langFilter = self.filter
                Settings.save(settings)
            }
        }
    }
    
    init() {
        filter = Settings.cached.langFilter
    }
    
    var onMoreCandidatesLoaded: ((CandidateOrganizer) -> Void)?
    var onReloadCandidates: ((CandidateOrganizer) -> Void)?
    
    func requestMoreCandidates(section: Int) {
        guard section == 0 else { return }
        loadMoreCandidates(reset: false)
    }
    
    /*var groupBy: GroupBy = .frequency {
        didSet {
            
        }
    }*/
    private var _candidateSource: CandidateSource?
    var candidateSource: CandidateSource? {
        get { _candidateSource }
        set {
            if _candidateSource !== newValue {
                _candidateSource = newValue
                NSLog("CandidateSource changed. Refreshing collection view.")
                
                // Reset to group by frequency on any source change.
                // groupBy = .frequency
                loadMoreCandidates(reset: true)
            }
        }
    }
    
    private var candidates = NSArray()
    private var candidateIndices: [Int] = []
    private var lastProcessedCandidateSourceIndex = 0
    
    private func loadMoreCandidates(reset: Bool) {
        if reset {
            candidateIndices = []
            if filter == .mixed {
                candidates = candidateSource?.candidates ?? []
            } else {
                candidates = NSMutableArray()
            }
            lastProcessedCandidateSourceIndex = 0
        }
        
        var loaded = true
        var candidateAdded = 0
        if let candidateSource = self.candidateSource {
            repeat {
                loaded = candidateSource.requestMoreCandidate()
                if candidateSource is AutoSuggestionCandidateSource || filter == .mixed { // Pass-thru mode.
                    candidates = candidateSource.candidates
                    candidateAdded += candidates.count - candidateIndices.count
                    candidateIndices.append(contentsOf: candidateIndices.count..<candidates.count)
                    lastProcessedCandidateSourceIndex = candidateSource.candidates.count
                } else { // Filtering mode.
                    for i in lastProcessedCandidateSourceIndex..<candidateSource.candidates.count {
                        guard let text = candidateSource.candidates[i] as? String,
                              let candidates = candidates as? NSMutableArray else { lastProcessedCandidateSourceIndex += 1; continue }
                        let source = candidateSource.getCandidateSource(i)
                        guard source == nil ||
                              filter == .chinese && source == .some(.rime) ||
                              filter == .english && source == .some(.english) else {
                            lastProcessedCandidateSourceIndex += 1;
                            continue
                        }
                        
                        candidates.add(text)
                        candidateIndices.append(i)
                        candidateAdded += 1
                        lastProcessedCandidateSourceIndex += 1
                    }
                }
            } while loaded && candidateAdded < 10
        }
        
        if reset || loaded {
            reset ? onReloadCandidates?(self) : onMoreCandidatesLoaded?(self)
        }
    }
    
    func getNumberOfSections() -> Int {
        return 1
    }
    
    func getCandidates(section: Int) -> NSArray {
        return candidates
    }
    
    func getCandidate(indexPath: IndexPath) -> String? {
        guard indexPath.section == 0 && indexPath.row < candidates.count else { return nil }
        
        return candidates[indexPath.row] as? String
    }
    
    func getCandidateIndex(indexPath: IndexPath) -> Int? {
        guard indexPath.section == 0 && indexPath.row < candidateIndices.count else { return nil }
        
        return candidateIndices[indexPath.row]
    }
}
