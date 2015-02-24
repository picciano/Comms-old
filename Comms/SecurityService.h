//
//  SecurityService.h
//  Comms
//
//  Created by Anthony Picciano on 2/10/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

#define ENCRYPTION_TEST_STRING @"Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hello, world! Hell"

@interface SecurityService : NSObject

+ (instancetype)sharedSecurityService;

- (NSData *)publicKeyForCurrentUser;
- (void)deleteKeypairForCurrentUser;
- (BOOL)privateKeyExistsForCurrentUser;

- (NSData *)encrypt:(NSString *)plaintext usingPublicKey:(NSData *)publicKey;
- (NSString *)decrypt:(NSData *)ciphertext;

- (BOOL)testEncryption;

@end
