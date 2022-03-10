//
//  NGramTable.m
//  CantoboardFramework
//
//  Created by Alex Man on 12/20/21.
//

#import <Foundation/Foundation.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <algorithm>
#include <set>
#include <unordered_map>
#include <string>

#import <CocoaLumberjack/DDLogMacros.h>
static const DDLogLevel ddLogLevel = DDLogLevelDebug;

#include "marisa/trie.h"
#include "NGram.h"
#include "Utils.h"

static short kMaxNumberOfTerms = 30;

using namespace std;
using namespace marisa;

@interface NSString (Unicode)
@property(readonly) NSUInteger lengthOfComposedChars;
@end

@implementation NSString (Unicode)
-(size_t) lengthOfComposedChars {
    __block size_t count = 0;
    [self enumerateSubstringsInRange:NSMakeRange(0, [self length])
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        count++;
    }];
    return count;
}
@end

@implementation PredictiveTextEngine {
    int fd;
    size_t fileSize;
    char* data;
    const NGramHeader* header;
    const Weight* weights;
    const char* isWordList;
    Trie trie;
}

- (void)dealloc {
    [self close];
}

- (void)close {
    if (data != nullptr && data != MAP_FAILED) {
        header = nullptr;
        weights = nullptr;
        isWordList = nullptr;
        DDLogInfo(@"Predictive text engine unmapping ngram table from memory...");
        munmap(data, fileSize);
        data = nullptr;
        DDLogInfo(@"Predictive text engine unmapped ngram table from memory.");
    }
    if (fd != -1) {
        close(fd);
        fd = -1;
        fileSize = 0;
        DDLogInfo(@"Predictive text engine closed ngram.");
    }
}

- (id)init:(NSString*) ngramFilePath {
    self = [super init];
    
    fd = -1;
    fileSize = 0;
    data = nullptr;
    header = nullptr;
    weights = nullptr;
    isWordList = nullptr;
    
    fd = open([ngramFilePath UTF8String], O_RDONLY);
    
    DDLogInfo(@"Predictive text engine opening ngram...");
    if (fd == -1) {
        NSString *s = [NSString stringWithFormat:@"Failed to open %@ ngram file. %s", ngramFilePath, strerror(errno)];
        DDLogInfo(@"Error: %@", s);
        return self;
    }
    
    struct stat buf;
    fstat(fd, &buf);
    fileSize = buf.st_size;
    data = (char*)mmap(nullptr, fileSize, PROT_READ, MAP_SHARED, fd, 0);
    
    DDLogInfo(@"Predictive text engine mapping ngram table into memory...");
    if (data == MAP_FAILED) {
        NSString *s = [NSString stringWithFormat:@"Predictive text engine failed to mmap ngram file. %s", strerror(errno)];
        DDLogInfo(@"Error: %@", s);
        [self close];
        return self;
    } else {
        header = (NGramHeader*)data;
        
        if (header->version != 0) {
            DDLogInfo(@"Predictive text engine doesn't support ngram file version %d.", header->version);
            [self close];
            return self;
        }
    }
    
    const NGramSectionHeader& trieSectionHeader = header->sections[NGramSectionId::trie];
    trie.map(data + trieSectionHeader.dataOffset, trieSectionHeader.dataSizeInBytes);
    
    const NGramSectionHeader& weightSectionHeader = header->sections[weight];
    weights = (Weight*)(data + weightSectionHeader.dataOffset);
    
    const NGramSectionHeader& isWordListSectionHeader = header->sections[isWord];
    isWordList = (const char*)(data + isWordListSectionHeader.dataOffset);
    
    DDLogInfo(@"Predictive text engine loaded.");
    return self;
}

static NSString* offensiveWords[] = {
    @"屌", @"𨳒", @"鳩", @"𨳊", @"閪", @"撚", @"柒", @"仆街", @"老母", @"老味", // TC
    @"鸠" // SC
};

- (NSArray*)predict:(NSString*) context filterOffensiveWords:(bool) shouldFilterOffensiveWords {
    if (header == nullptr) {
        return [[NSArray alloc] init];
    }
    // header->maxN indicates the max length of suggested text.
    // That means we should search for suffix with length up to max length-1 of the context.
    // To start the search, move the pointer backward from the end of the string by max length-1 times.
    NSUInteger backward = header->maxN - 1;
    NSUInteger currentIndex = context.length;
    while (currentIndex > 0 && backward > 0) {
        NSRange curCharRange = [context rangeOfComposedCharacterSequenceAtIndex:currentIndex - 1];
        currentIndex = curCharRange.location;
        backward--;
    }
    
    // Now we are pointing to the beginning of the longest suffix. Search for the whole suffix.
    // Then move forward by 1 composed char then search again.
    // e.g. let context = abcdefg, max length = 6,
    // The first iteration would search for cdefg, then defg, etc. At the end it would search for g.
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSMutableSet *dedupSet = [[NSMutableSet alloc] init];
    DDLogInfo(@"PredictiveTextEngine context: %@ currentIndex: %lu", context, (unsigned long)currentIndex);
    while (currentIndex < context.length) {
        NSString *prefixToSearch = [context substringWithRange:NSMakeRange(currentIndex, context.length - currentIndex)];
        NSRange curCharRange = [context rangeOfComposedCharacterSequenceAtIndex:currentIndex];
        currentIndex += curCharRange.length;
        DDLogInfo(@"PredictiveTextEngine searching prefix: %@", prefixToSearch);
        [self search:prefixToSearch output:results dedupSet:dedupSet shouldFilterOffensiveWords:shouldFilterOffensiveWords];
    }
    
    NSArray *finalResults = [results subarrayWithRange:NSMakeRange(0, min((NSUInteger)kMaxNumberOfTerms, [results count]))];
    return finalResults;
}

- (bool)isWord:(size_t) keyId {
    size_t byteOffset = keyId / 8;
    short bitOffset = keyId % 8;
    char encodedByte = isWordList[byteOffset];
    
    return 1 == ((encodedByte >> bitOffset) & 1);
}

struct PredictiveResult {
    string text;
    bool isWord;
};

- (void)search:(NSString*) prefix output:(NSMutableArray*) output dedupSet:(NSMutableSet*) dedupSet shouldFilterOffensiveWords:(bool) shouldFilterOffensiveWords {
    if (header == nullptr) {
        return;
    }
    auto cmp = [&](const pair<size_t, PredictiveResult>& key1, const pair<size_t, PredictiveResult>& key2) {
        return weights[key1.first] > weights[key2.first];
    };
    set<pair<size_t, PredictiveResult>, decltype(cmp)> orderedResults(cmp);

    Agent trieAgent;
    const char* prefixCStr = [prefix UTF8String];
    if (prefixCStr == nullptr) {
        return;
    }
    trieAgent.set_query(prefixCStr);
    while (trie.predictive_search(trieAgent)) {
        const Key& key = trieAgent.key();
        string keyText = string(key.ptr(), key.length());
        bool isWord = [self isWord:key.id()];
        PredictiveResult predictiveResult({ keyText, isWord });
        orderedResults.insert({ key.id(), predictiveResult });
    }
    
    for (auto it = orderedResults.begin(); it != orderedResults.end(); ++it) {
        const auto& key = it->second;
        const auto& text = key.text;
        const auto isWord = it->second.isWord;
        NSString *fullText = [[NSString alloc] initWithBytes:text.c_str()
                                                      length:text.length()
                                                    encoding:NSUTF8StringEncoding];
        
        bool shouldFilter = false;
        if (shouldFilterOffensiveWords) {
            for (NSString* offensiveWord : offensiveWords) {
                if ([fullText containsString: offensiveWord]) {
                    shouldFilter = true;
                    break;
                }
            }
            if (shouldFilter) continue;
        }
        
        NSString *toAdd = nullptr;
        
        NSRange suffixRange = NSMakeRange([prefix length], [fullText length] - [prefix length]);
        NSString *suffix = [fullText substringWithRange:suffixRange];
        
        if (isWord) {
            toAdd = suffix;
        } else {
            Agent trieAgent;
            const char* suffixCStr = [suffix UTF8String];
            if (suffixCStr == nullptr) {
                continue;
            }
            trieAgent.set_query(suffixCStr);
            
            if ([suffix lengthOfComposedChars] == 1) {
                // If the suffix has just a single char, always suggest it.
                NSRange lastCharRange = [fullText rangeOfComposedCharacterSequenceAtIndex:fullText.length - 1];
                NSString *lastChar = [fullText substringWithRange:lastCharRange];
                toAdd = lastChar;
            } else if (trie.lookup(trieAgent)) {
                // If suffix is a word, suggest the whole word.
                size_t suffixKeyId = trieAgent.key().id();
                bool isSuffixWord = [self isWord:suffixKeyId];
                if (isSuffixWord) toAdd = suffix;
            }
        }
        
        if (toAdd == nullptr || toAdd.length == 0) continue;

        DDLogInfo(@"PredictiveTextEngine fullText %@ toAdd %@ weight %f isWord %s", fullText, toAdd, weights[it->first], isWord ? "true" : "false");
        if (![dedupSet containsObject:toAdd]) {
            [output addObject:toAdd];
            [dedupSet addObject:toAdd];
        }
    }
}

@end
