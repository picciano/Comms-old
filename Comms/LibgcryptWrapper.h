//
//  LibgcryptWrapper.h
//  Comms
//
//  Created by Anthony Picciano on 2/23/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LibgcryptWrapper : NSObject

+ (NSData *)generateKeypair;
+ (NSData *)getPublicKeyFromKeypair:(NSData *)keypair;
+ (NSData *)getPrivateKeyFromKeypair:(NSData *)keypair;

@end
