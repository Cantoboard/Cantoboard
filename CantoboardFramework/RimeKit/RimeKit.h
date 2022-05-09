#ifndef __RIME_KIT_H__
#define __RIME_KIT_H__

#import <Foundation/Foundation.h>

typedef uintptr_t RimeSessionId;

NS_SWIFT_NAME(RimeSession)
@interface RKRimeSession: NSObject

-(void)processKey:(int)keycode modifier:(int)modifier;
-(void)setCaretPos:(size_t) caretPos;
-(void)resetAndUpdateContext;

-(NSString *)getCandidate:(unsigned int) index;
-(NSString *)getComment:(unsigned int) index;
-(unsigned int)getLoadedCandidatesCount;

-(bool)loadMoreCandidates;
-(void)setCandidateMenuToFirstPage;

-(bool)selectCandidate:(int)candidateIndex;
-(NSString *)getCommitedText;

-(bool)getOption:(NSString *)name;
-(void)setOption:(NSString *)name value:(bool)value;

-(NSString *)getCurrentSchemaId;
-(void)setCurrentSchema:(NSString *)schemaId;

@property int compositionCaretBytePosition, rawInputCaretBytePosition;
@property bool isFirstCandidateCompleteMatch;
@property (readonly, strong) NSString *compositionText, *commitTextPreview, *rawInput;
@property (readonly) RimeSessionId sessionId;

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

-(id)init:(NSObject<RKRimeNotificationHandler> *)eventListener sharedDataPath:(NSString *)sharedDataPath userDataPath:(NSString *)userDataPath;
-(void)close;

-(NSString *)version;
-(NSString *)quickStartFlagFilePath;
+(NSString *)quickStartFlagFileName;

// RKRimeSession is owned by RKRimeApi. Opening sessions are invalidated on close().
-(RKRimeSession *)createSession;
// RKRimeApi owns RKRimeSession to support invalidating outstanding sessions on close(). Please do not store strong ref to RKRimeSession.
-(void)closeSession:(RKRimeSession *)session;

@property RKRimeApiState state;

@end

@protocol RKRimeNotificationHandler
-(void)onStateChange:(RKRimeApi *)rimeApi newState:(RKRimeApiState)newState;
-(void)onNotification:(NSString *)messageType messageValue:(NSString *)messageValue;
@end

#endif /* __RIME_KIT_H__ */
