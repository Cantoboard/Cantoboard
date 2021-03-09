//
//  RKUtils.h
//  KeyboardKit
//
//  Created by Alex Man on 1/20/21.
//

#ifndef RKUtils_h
#define RKUtils_h

#define NSLog(__FORMAT__, ...) NSLog((@"%s:%d %s " __FORMAT__), __FILE_NAME__, __LINE__, __func__, ##__VA_ARGS__)

static inline NSString* nullSafeToNSString(const char* cstring) {
    return cstring ? [NSString stringWithUTF8String:cstring] : @"";
}

#endif /* RKUtils_h */
