//
//  RimePluginExtension.h
//  CantoboardFramework
//
//  Created by Alex Man on 5/7/22.
//

#ifndef RimePluginExtension_h
#define RimePluginExtension_h

#import "RimeKit.h"

// Extend RKRimeSession to expose methods added by Cantoboard Rime plugin module.
@interface RKRimeSession (RimePluginExtension)
-(void)setInput:(NSString*) input;
@property (readonly) size_t userSelectedTextLength;
@end

// Expose ten keys related methods added by Cantoboard Rime plugin module.
@interface TenKeysHelper: NSObject
+ (NSArray*)listPossiblePrefixes:(NSString*) input;
@end

#endif /* RimePluginExtension_h */
