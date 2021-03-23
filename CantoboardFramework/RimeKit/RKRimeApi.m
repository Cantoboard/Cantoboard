//
//  RimeKit.m
//  RimePlayground
//
//  Created by Alex Man on 1/13/21.
//  Copyright © 2021 Alex Man. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wstrict-prototypes"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#include <rime_api.h>
#pragma clang diagnostic pop

#import "RimeKit.h"

#include "RKUtils.h"

@interface RKRimeSession (extended)
- (id)init:(RimeApi*)rimeApi sessionId:(RimeSessionId)sessionId;
- (void)close;
@end

@implementation RKRimeApi {
    RimeApi *_rimeApi;
    NSObject<RKRimeNotificationHandler> *_rimeEventListener;
    NSMutableArray<RKRimeSession*> *_sessions;
}

static bool hasSetupRimeTrait = false;

static void rimeNotificationHandler(void* context_object, RimeSessionId session_id, const char* message_type, const char* message_value) {
    NSLog(@"Event type: %s value: %s.\n", message_type, message_value);
    RKRimeApi* zelf = (__bridge RKRimeApi*) context_object;
    
    if (zelf->_rimeEventListener) {
        if (0 == strcmp(message_type, "deploy")) {
            RKRimeApiState newState = zelf->_state;
            if (0 == strcmp(message_value, "start")) {
                newState = RKRimeApiStateDeploying;
            } else if (0 == strcmp(message_value, "success")) {
                newState = RKRimeApiStateSucceeded;
            } else if (0 == strcmp(message_value, "failure")) {
                newState = RKRimeApiStateFailure;
            } else {
                NSLog("Ignoring unknown Rime deploy state: %s.", message_value);
                return;
            }
            // NSLog("Rime state: %ld -> %ld.", zelf->_state, newState);
            [zelf->_rimeEventListener onStateChange: zelf newState: newState];
            zelf->_state = newState;
        } else {
            [zelf->_rimeEventListener onNotification:[NSString stringWithUTF8String:message_type] messageValue:[NSString stringWithUTF8String:message_value]];
        }
    }
}

-(id)init:(NSObject<RKRimeNotificationHandler>*) eventListener sharedDataPath:(NSString*) sharedDataPath userDataPath:(NSString*) userDataPath {
    self = [super init];
    
    _rimeEventListener = eventListener;
    _sessions = [NSMutableArray array];
    _rimeApi = rime_get_api();
    _state = RKRimeApiStateUninitialized;
    [self initRime: sharedDataPath userDataPath: userDataPath];
    return self;
}

-(void)initRime:(NSString*) sharedDataPath userDataPath:(NSString*) userDataPath {
    NSLog(@"Initializing Rime API.");
    RIME_STRUCT(RimeTraits, traits);
    
    if (!hasSetupRimeTrait) {
        traits.shared_data_dir = sharedDataPath.UTF8String;
        traits.user_data_dir = userDataPath.UTF8String;
        traits.distribution_code_name = "Rime-iOS";
        traits.distribution_name = "Rime-iOS";
        traits.distribution_version = "0.1";
        traits.app_name = "rime.iOS";
        _rimeApi->setup(&traits);
        hasSetupRimeTrait = true;
    }
    
    _rimeApi->set_notification_handler(&rimeNotificationHandler, (__bridge void*) self);
    _rimeApi->initialize(NULL);

    if (_rimeApi->start_maintenance(true)) {
        // _rimeApi->join_maintenance_thread();
    } else {
        NSLog(@"Failed to initialize Rime API.");
    }
}

-(void)close {
    NSLog(@"Closing Rime API...");
    _sessions = nil;
    if (_rimeApi) {
        _rimeApi->set_notification_handler(NULL, NULL);
        _rimeApi->finalize();
        _rimeApi = NULL;
    }
    _state = RKRimeApiStateUninitialized;
    NSLog(@"Closed Rime API.");
}

-(NSString*)getVersion {
    return nullSafeToNSString(_rimeApi->get_version());
}

-(RKRimeSession*)createSession {
    RimeSessionId sessionId = _rimeApi->create_session();
    if (sessionId == 0) return NULL;
    RKRimeSession* newSession = [[RKRimeSession alloc] init:_rimeApi sessionId: sessionId];
    [_sessions addObject: newSession];
    return newSession;
}

-(void)closeSession: (RKRimeSession*) session {
    [session close];
    [_sessions removeObject:session];
}

-(void)dealloc {
    [self close];
}

@end
