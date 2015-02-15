//
//  AppInfoManager.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "AppInfoManager.h"
#import "CommsIAPHelper.h"

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

+ (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static volatile int32_t NumberOfCallsToSetVisible = 0;
    int32_t newValue = OSAtomicAdd32((setVisible ? +1 : -1), &NumberOfCallsToSetVisible);
    
    NSAssert(newValue >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(newValue > 0)];
}

@end
