//
//  RimePluginExtension.m
//  CantoboardFramework
//
//  Created by Alex Man on 5/7/22.
//

#import <Foundation/Foundation.h>
#include <set>
#include <string>

#import "RimePluginExtension.h"

// Adhoc import:
namespace cantoboard {

extern size_t GetSelectedTextEndIndex(RimeSessionId session_id);
extern void List10KeysPrefixes(const char* prefix, std::set<std::string> &results);
extern void SetInput(RimeSessionId session_id, const std::string& value);
extern bool UnlearnCandidate(RimeSessionId session_id, size_t candidate_index);

} // namespace cantoboard

@implementation RKRimeSession (RimePluginExtension)

-(void)setInput:(NSString*) input {
    cantoboard::SetInput(self.sessionId, [input UTF8String]);
    [self resetAndUpdateContext];
}

-(size_t)userSelectedTextLength {
    return cantoboard::GetSelectedTextEndIndex(self.sessionId);
}

-(bool)unlearnCandidate:(size_t) candidateIndex {
    return cantoboard::UnlearnCandidate(self.sessionId, candidateIndex);
}

@end

@implementation TenKeysHelper: NSObject

+(NSArray*)listPossiblePrefixes:(NSString*) input {
    // DDLogInfo(@"TenKeysHelper::listPossiblePrefixes input: %@", input);
    std::set<std::string> prefixes;
    
    cantoboard::List10KeysPrefixes([input UTF8String], prefixes);
    
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:prefixes.size()];
    
    for (auto&& p : prefixes) {
        NSString *pStr = [[NSString alloc] initWithBytes:p.c_str()
                                                  length:p.length()
                                                encoding:NSUTF8StringEncoding];
        [results addObject:pStr];
    }
    
    return results;
}

@end
