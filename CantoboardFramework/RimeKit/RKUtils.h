//
//  RKUtils.h
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

#ifndef RKUtils_h
#define RKUtils_h

#import <CocoaLumberjack/DDLogMacros.h>
static const DDLogLevel ddLogLevel = DDLogLevelDebug;

// #define DDLogInfo(__FORMAT__, ...) DDLogInfo((@"%s:%d %s " __FORMAT__), __FILE_NAME__, __LINE__, __func__, ##__VA_ARGS__)

static NSString *EMPTY_STRING = @"";

static inline NSString* nullSafeToNSString(const char *cstring) {
    return cstring ? [NSString stringWithUTF8String:cstring] : EMPTY_STRING;
}

#endif /* RKUtils_h */
