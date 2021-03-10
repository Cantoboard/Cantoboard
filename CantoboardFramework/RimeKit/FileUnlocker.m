//
//  FileUnlocker.m
//  KeyboardKit
//
//  Created by Alex Man on 2/20/21.
//
#include <fcntl.h>

#import <Foundation/Foundation.h>

#import "RimeKit.h"

@implementation FileUnlocker

// Unlock all opened FDs to prevent iOS from killing us on suspension.
+ (void)unlockAllOpenedFiles {
    NSLog(@"unlockAllOpenedFiles");
    for (int fd = 0; fd < (int) FD_SETSIZE; fd++) {        
        struct flock unlock;
        unlock.l_type = F_UNLCK;
        unlock.l_start = 0;
        unlock.l_whence = SEEK_SET;
        unlock.l_len = 0;
        fcntl(fd, F_SETLK, &unlock);
        // int ret = fcntl(fd, F_SETLK, &unlock);
        // if (ret >= 0) NSLog(@"Unlocked fd %d", fd);
    }
}

@end
