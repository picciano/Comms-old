//
//  AppInfoManager.h
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppInfoManager : NSObject

+ (BOOL)isProVersion;
+ (NSString *)bundleName;

@end
