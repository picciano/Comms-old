//
//  AppInfoManager.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "AppInfoManager.h"

@implementation AppInfoManager

+ (BOOL)isProVersion {
    
#ifdef PRO
    return YES;
#else
    return NO;
#endif
    
}

+ (NSString *)bundleName {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
}

@end
