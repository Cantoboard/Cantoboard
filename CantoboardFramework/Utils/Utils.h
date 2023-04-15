//
//  Utils.h
//  Cantoboard
//
//  Created by Alex Man on 3/22/21.
//

#ifndef Utils_h
#define Utils_h

#import "RimePluginExtension.h"

typedef NS_OPTIONS(uint8_t, IICore) {
    IICoreT = 1 << 0,
    IICoreG = 1 << 1,
};

typedef struct __attribute__((packed)) {
    // There are just 214 radicals.
    // The most complicated Chinese char has 58 stroke.
    uint8_t radical, radicalStroke, totalStroke;
    IICore iiCore;
} UnihanEntry;

@interface LevelDbTable: NSObject
- (id)init:(NSString*) dbPath createDbIfMissing:(bool) createDbIfMissing;
- (NSString*)get:(NSString*) word;
- (UnihanEntry)getUnihanEntry:(uint32_t) charInUtf32;
- (bool)put:(NSString*) key value:(NSString*) value;
- (bool)delete:(NSString*) key;
+ (void)createEnglishDictionary:(NSArray*) textFilePaths dictDbPath:(NSString*) dbPath;
+ (void)createUnihanDictionary:(NSString*) csvPath dictDbPath:(NSString*) dbPath;
@end

@interface PredictiveTextEngine: NSObject
- (id)init:(NSString*) ngramFilePath;
- (NSArray*)predict:(NSString*) contextText filterOffensiveWords:(bool) shouldFilterOffensiveWords;
@end

#endif /* Utils_h */
