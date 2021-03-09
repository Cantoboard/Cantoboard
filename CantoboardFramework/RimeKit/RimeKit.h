#ifndef __RIME_KIT_H__
#define __RIME_KIT_H__

#import <Foundation/Foundation.h>

NS_SWIFT_NAME(RimeSession)
@interface RKRimeSession: NSObject

-(void)processKey:(int)keycode modifier:(int)modifier;
-(bool)getCandidates:(NSMutableArray<NSString*>*)output comments:(NSMutableArray<NSString*>*)comments; // Return true if the call loaded any candidates
-(void)selectCandidate:(int)candidateIndex;
-(NSString*)getCommitedText;
-(bool)getOption:(NSString*)name;
-(void)setOption:(NSString*)name value:(bool)value;

@property int compositionCaretBytePosition;
@property (readonly, strong) NSString *compositionText, *commitTextPreview;

@end

typedef NS_ENUM(NSInteger, RKRimeApiState) {
    RKRimeApiStateUninitialized,
    RKRimeApiStateDeploying,
    RKRimeApiStateFailure,
    RKRimeApiStateSucceeded
} NS_SWIFT_NAME(RimeApiState);

NS_SWIFT_NAME(RimeNotificationHandler)
@protocol RKRimeNotificationHandler;

NS_SWIFT_NAME(RimeApi)
@interface RKRimeApi: NSObject

-(id)init:(NSObject<RKRimeNotificationHandler>*) eventListener sharedDataPath:(NSString*) sharedDataPath userDataPath:(NSString*) userDataPath;
-(void)close;

-(NSString*)getVersion;
// RKRimeSession is owned by RKRimeApi. Opening sessions are invalidated on close().
-(RKRimeSession*)createSession;
// RKRimeApi owns RKRimeSession to support invalidating outstanding sessions on close(). Please do not store strong ref to RKRimeSession.
-(void)closeSession:(RKRimeSession*) session;

@property RKRimeApiState state;

@end

@protocol RKRimeNotificationHandler
-(void)onStateChange:(RKRimeApi*) rimeApi newState:(RKRimeApiState) newState;
-(void)onNotification:(NSString*) messageType messageValue:(NSString*) messageValue;
@end

// This class doesn't really belong to RimeKit.
@interface FileUnlocker: NSObject
+ (void)unlockAllOpenedFiles;
@end

#endif /* __RIME_KIT_H__ */
