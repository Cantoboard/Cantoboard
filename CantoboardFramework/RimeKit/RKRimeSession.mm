//
//  RKRimeSession.m
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#pragma clang diagnostic ignored "-Wdocumentation-deprecated-sync"
#include <Rime/rime_api.h>
#pragma clang diagnostic pop

#import "RimeKit.h"
#import "RKUtils.h"

@implementation RKRimeSession {
    RimeApi *_rimeApi;
    RimeSessionId _sessionId;
    bool _candidatesAllLoaded;
    int _compositionCaretBytePosition;
    NSMutableArray<NSString *> *_candidates;
    NSMutableArray<NSString *> *_comments;
    bool _isFirstCandidateCompleteMatch;
}

-(id)init:(RimeApi *)rimeApi sessionId:(RimeSessionId)sessionId {
    self = [super init];
    
    _rimeApi = rimeApi;
    _sessionId = sessionId;
    _candidatesAllLoaded = false;
    _compositionCaretBytePosition = 0;
    _isFirstCandidateCompleteMatch = false;
    _rawInputCaretBytePosition = 0;
    
    _candidates = [NSMutableArray array];
    _comments = [NSMutableArray array];
    
    if (_sessionId == 0) {
        @throw [NSException exceptionWithName:@"SessionIdZeroException" reason:@"sessionId cannot be zero." userInfo:nil];
    }
    
    DDLogInfo(@"Created Rime Session: %p", (void*)_sessionId);
    return self;
}

-(void)validateSession {
    if (_sessionId == 0 || !_rimeApi->find_session(_sessionId)) {
        @throw [NSException exceptionWithName:@"SessionInvalidStateException" reason:@"Session is closed." userInfo:nil];
    }
}

-(void)close {
    if (_sessionId != 0) {
        _rimeApi->destroy_session(_sessionId);
        DDLogInfo(@"Destroyed Rime Session: %p", (void*)_sessionId);
        _sessionId = 0;
    }
}

-(void)setCaretPos:(size_t) caretPos {
    [self validateSession];
    _rimeApi->set_caret_pos(_sessionId, caretPos);
    [self resetAndUpdateContext];
}

-(void)processKey:(int)keycode modifier:(int)modifier {
    [self validateSession];
    // DDLogInfo(@"Process key %p %c", (void*)_sessionId, (char)keycode);
    _rimeApi->process_key(_sessionId, keycode, modifier);
    [self resetAndUpdateContext];
}

-(void)resetAndUpdateContext {
    _candidatesAllLoaded = false;
    _candidates = [NSMutableArray array];
    _comments = [NSMutableArray array];
    _candidatesAllLoaded = false;
    [self updateContext];
}

-(NSString *)getCandidate:(unsigned int) index {
    if (index >= _candidates.count) return nil;
    return _candidates[index];
}

-(NSString *)getComment:(unsigned int) index {
    if (index >= _comments.count) return nil;
    return _comments[index];
}

-(unsigned int)getLoadedCandidatesCount {
    return (unsigned int)_candidates.count;
}

-(bool)loadMoreCandidates {
    if (_candidatesAllLoaded) return false;
    
    RIME_STRUCT(RimeContext, ctx);
    if (![self getContext:&ctx]) { return false; }
    
    bool hasLoadedData = false;
    for (int i = 0; i < ctx.menu.num_candidates; ++i) {
        RimeCandidate* c = ctx.menu.candidates + i;
        
        [_candidates addObject:nullSafeToNSString(c->text)];
        [_comments addObject:nullSafeToNSString(c->comment)];
        
        hasLoadedData = true;
    }
    
    if (ctx.menu.is_last_page || ctx.menu.num_candidates == 0) {
        _candidatesAllLoaded = true;
        // DDLogInfo("Hit last page.");
    } else {
        _rimeApi->process_key(_sessionId, 0xff56, 0);
    }
    _rimeApi->free_context(&ctx);
    
    return !_candidatesAllLoaded;
}

-(bool)selectCandidate:(int)candidateIndex {
    [self validateSession];
    // DDLogInfo(@"Selecting %p %d.", (void*)_sessionId, candidateIndex);
    bool ret = _rimeApi->select_candidate(_sessionId, candidateIndex);
    _candidatesAllLoaded = false;
    [self updateContext];
    return ret;
}

-(NSString *)getCommitedText {
    RIME_STRUCT(RimeCommit, commit);
    @try {
        if (_rimeApi->get_commit(_sessionId, &commit)) {
            _candidatesAllLoaded = false;
            return nullSafeToNSString(commit.text);
        }
    } @finally {
        _rimeApi->free_commit(&commit);
    }
    return nil;
}

-(void)updateContext {
    RIME_STRUCT(RimeContext, ctx);
    @try {
        if (![self getContext:&ctx]) { return; }
        
        _compositionText = nullSafeToNSString(ctx.composition.preedit);
        _commitTextPreview = nullSafeToNSString(ctx.commit_text_preview);
        _rawInput = nullSafeToNSString(_rimeApi->get_input(_sessionId));
        
        _compositionCaretBytePosition = ctx.composition.cursor_pos;
        _isFirstCandidateCompleteMatch = ctx.composition.sel_end == ctx.composition.length;
        _rawInputCaretBytePosition = (int)_rimeApi->get_caret_pos(_sessionId);
        
        // DDLogInfo(@"updateContext _compositionCaretBytePosition %d sel_start %d _rawInputCaretBytePosition %d", _compositionCaretBytePosition, sel_start, _rawInputCaretBytePosition);
        return;
    } @finally {
        _rimeApi->free_context(&ctx);
    }
}

-(bool)getOption:(NSString *)name {
    [self validateSession];
    return _rimeApi->get_option(_sessionId, name.UTF8String);
}

-(void)setOption:(NSString *)name value:(bool)value {
    [self validateSession];
    _rimeApi->set_option(_sessionId, name.UTF8String, value);
}

-(NSString *)getCurrentSchemaId {
    char schemaId[1024];
    _rimeApi->get_current_schema(_sessionId, schemaId, sizeof(schemaId));
    return [NSString stringWithUTF8String:schemaId];
}

-(void)setCurrentSchema:(NSString *)schemaId {
    _rimeApi->select_schema(_sessionId, [schemaId UTF8String]);
}

-(void)setCandidateMenuToFirstPage {
    RIME_STRUCT(RimeContext, ctx);
    bool isFirstPage = false;
    
    _candidates = [NSMutableArray array];
    _comments = [NSMutableArray array];
    
    do {
        if (![self getContext:&ctx]) { return; }
        
        _rimeApi->process_key(_sessionId, 0xff55, 0);
        
        isFirstPage = ctx.menu.page_no == 0;
        _rimeApi->free_context(&ctx);
    } while (!isFirstPage);

    _candidatesAllLoaded = false;
}

-(bool)getContext:(RimeContext *)ctx {
    if (!_rimeApi->get_context(_sessionId, ctx)) {
        DDLogInfo(@"%p get_context() failed.", (void*)_sessionId);
        _compositionText = @"";
        _commitTextPreview = @"";
        _rawInput = @"";
        _candidatesAllLoaded = false;
        _compositionCaretBytePosition = 0;
        _rawInputCaretBytePosition = 0;
        _rimeApi->free_context(ctx);
        return false;
    }
    return true;
}

@end
