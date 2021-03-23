//
//  Utils.h
//  Cantoboard
//
//  Created by Alex Man on 3/22/21.
//

#ifndef Utils_h
#define Utils_h

@interface EnglishDictionary: NSObject
- (id)init:(NSString*) dbPath;
- (bool)hasWord:(NSString*) word;

+ (bool)createDb:(NSString*) textFilePath dbPath:(NSString*) dbPath;
@end

@interface FileUnlocker: NSObject
+ (void)unlockAllOpenedFiles;
@end

#endif /* Utils_h */
