//
//  AppInfoManager.h
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>

@interface AppInfoManager : NSObject

+ (BOOL)isProVersion;
+ (NSString *)bundleName;
+ (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible;

@end
