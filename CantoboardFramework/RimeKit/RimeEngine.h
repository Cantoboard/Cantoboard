#ifndef __RIME_ENGINE_H__
#define __RIME_ENGINE_H__

#import <Foundation/Foundation.h>

//! Project version number for RimeEngine.
FOUNDATION_EXPORT double RimeEngineVersionNumber;

//! Project version string for RimeEngine.
FOUNDATION_EXPORT const unsigned char RimeEngineVersionString[];

@protocol RimeEngineEventListener
-(void)onRimeEngineDeploy:(NSString*) event;
-(void)onCommitText:(NSString*) text;
@end

@interface RimeSession: NSObject

-(void)close;
-(void)processKey:(int)keycode;
-(bool)getCandidates:(NSMutableArray<NSString*>*)output; // Return true when there's more data unfetched.
-(void)selectCandidate:(int)candidateIndex;

@property (readonly, strong) NSString* commitTextPreview;
@property (readonly, strong) NSString* preedit;

@end

@interface RKRimeApi: NSObject

-(id)init:(NSObject<RimeEngineEventListener>*) eventListener sharedDataPath:(NSString*) sharedDataPath userDataPath:(NSString*) userDataPath;
-(void)close;

-(NSString*)getVersion;

-(RimeSession*)createSession;

@end

#endif
