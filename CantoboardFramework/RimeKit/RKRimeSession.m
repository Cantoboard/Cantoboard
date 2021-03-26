//
//  RKRimeSession.m
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#include "rime_api.h"
#pragma clang diagnostic pop

#import "RimeKit.h"
#import "RKUtils.h"

@implementation RKRimeSession {
    RimeApi* _rimeApi;
    RimeSessionId _sessionId;
    bool _candidatesAllLoaded;
    int _compositionCaretBytePosition;
}

-(id)init:(RimeApi*)rimeApi sessionId:(RimeSessionId)sessionId {
    self = [super init];
    
    _rimeApi = rimeApi;
    _sessionId = sessionId;
    _candidatesAllLoaded = false;
    _compositionCaretBytePosition = 0;
    _rawInputCaretBytePosition = 0;
    
    if (_sessionId == 0) {
        @throw [NSException exceptionWithName:@"SessionIdZeroException" reason:@"sessionId cannot be zero." userInfo:nil];
    }
    
    NSLog(@"Created Rime Session: %p", (void*)_sessionId);
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
        NSLog(@"Destroyed Rime Session: %p", (void*)_sessionId);
        _sessionId = 0;
    }
}

-(void)processKey:(int)keycode modifier:(int)modifier {
    [self validateSession];
    // NSLog(@"Process key %p %c", (void*)_sessionId, (char)keycode);
    _rimeApi->process_key(_sessionId, keycode, modifier);
    _candidatesAllLoaded = false;
    [self updateContext];
}

// Return true when this call loaded data.
-(bool)getCandidates:(NSMutableArray<NSString*>*)output comments:(NSMutableArray<NSString*>*)comments {
    if (_candidatesAllLoaded) return false;
    
    RIME_STRUCT(RimeContext, ctx);
    if (!_rimeApi->get_context(_sessionId, &ctx)) {
        NSLog(@"%p get_context() failed.", (void*)_sessionId);
        // _candidates = nil;
        _compositionText = @"";
        _commitTextPreview = @"";
        _rawInput = @"";
        _candidatesAllLoaded = false;
        _compositionCaretBytePosition = 0;
        _rawInputCaretBytePosition = 0;
        // TODO Should I throw?
        _rimeApi->free_context(&ctx);
        return false;
    }
    
    bool hasLoadedData = false;
    for (int i = 0; i < ctx.menu.num_candidates; ++i) {
        RimeCandidate* c = ctx.menu.candidates + i;
        if (!c->text) continue;
        
        [output addObject:nullSafeToNSString(c->text)];
        [comments addObject:nullSafeToNSString(c->comment)];
        
        hasLoadedData = true;
        // if
        // NSLog("%s %s %d %d", c->text, c->comment, ctx.composition.sel_start, ctx.composition.sel_end);
        // [_candidateComments addObject:nullSafeToNSString(c->comment)];
    }
    
    if (ctx.menu.is_last_page) {
        _candidatesAllLoaded = true;
        // NSLog("Hit last page.");
    } else {
        _rimeApi->process_key(_sessionId, 0xff56, 0);
    }
    _rimeApi->free_context(&ctx);
    return hasLoadedData;
}

-(void)selectCandidate:(int)candidateIndex {
    [self validateSession];
    // NSLog(@"Selecting %p %d.", (void*)_sessionId, candidateIndex);
    _rimeApi->select_candidate(_sessionId, candidateIndex);
    _candidatesAllLoaded = false;
    [self updateContext];
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
        if (!_rimeApi->get_context(_sessionId, &ctx)) {
            NSLog(@"%p get_context() failed.", (void*)_sessionId);
            _compositionText = @"";
            _commitTextPreview = @"";
            _rawInput = @"";
            _candidatesAllLoaded = false;
            _compositionCaretBytePosition = 0;
            _rawInputCaretBytePosition = 0;
            // TODO Should I throw?
            return;
        }
        
        _compositionText = nullSafeToNSString(ctx.composition.preedit);
        _commitTextPreview = nullSafeToNSString(ctx.commit_text_preview);
        _rawInput = nullSafeToNSString(_rimeApi->get_input(_sessionId));
        
        _compositionCaretBytePosition = ctx.composition.cursor_pos;
        _rawInputCaretBytePosition = (int)_rimeApi->get_caret_pos(_sessionId);
        
        // NSLog(@"updateContext");
        return;
    } @finally {
        _rimeApi->free_context(&ctx);
    }
}

-(bool)getOption:(NSString*)name {
    [self validateSession];
    return _rimeApi->get_option(_sessionId, name.UTF8String);
}

-(void)setOption:(NSString*)name value:(bool)value {
    [self validateSession];
    _rimeApi->set_option(_sessionId, name.UTF8String, value);
}

-(void)setCandidateMenuToFirstPage {
    RIME_STRUCT(RimeContext, ctx);
    bool isFirstPage = false;
    do {
        if (!_rimeApi->get_context(_sessionId, &ctx)) {
            NSLog(@"%p get_context() failed.", (void*)_sessionId);
            _compositionText = @"";
            _commitTextPreview = @"";
            _rawInput = @"";
            _candidatesAllLoaded = false;
            _compositionCaretBytePosition = 0;
            _rawInputCaretBytePosition = 0;
            _rimeApi->free_context(&ctx);
            return;
        }
        
        _rimeApi->process_key(_sessionId, 0xff55, 0);
        
        isFirstPage = ctx.menu.page_no == 0;
        _rimeApi->free_context(&ctx);
    } while (!isFirstPage);

    _candidatesAllLoaded = false;
}

@end
