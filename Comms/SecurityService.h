//
//  SecurityService.h
//  Comms
//
//  Created by Anthony Picciano on 2/10/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SECURITY_SERVICE_BIT_LENGTH     2048

@interface SecurityService : NSObject

+ (instancetype)sharedSecurityService;

- (NSData *)getPublicKeyBits;
- (void)deleteKeyPair;

@end