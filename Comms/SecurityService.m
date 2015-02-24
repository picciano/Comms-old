//
//  SecurityService.m
//  Comms
//
//  Created by Anthony Picciano on 2/10/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "SecurityService.h"
#import "LibgcryptWrapper.h"
#import "KeychainWrapper.h"
#import "CocoaLumberjack.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;
static const NSString * PRIVATE_KEY = @"private-key";
static const NSString * PUBLIC_KEY = @"public-key";

@implementation SecurityService

static SecurityService * __sharedSecurityService = nil;

+ (instancetype)sharedSecurityService {
    @synchronized(self) {
        if (__sharedSecurityService == nil) {
            __sharedSecurityService = [[SecurityService alloc] init];
        }
    }
    return __sharedSecurityService;
}

- (NSData *)publicKeyForCurrentUser {
    NSAssert([PFUser currentUser] != nil, @"Current user must not be nil.");
    NSString *key = [self publicKeyIdentifierForCurrentUser];
    NSData *publicKey = [KeychainWrapper dataFromMatchingIdentifier:key];
    if (publicKey) {
        return publicKey;
    } else {
        return [self generateKeyPair];
    }
}

- (void)deleteKeypairForCurrentUser {
    NSAssert([PFUser currentUser] != nil, @"Current user must not be nil.");
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:[self privateKeyIdentifierForCurrentUser]];
    [KeychainWrapper deleteItemFromKeychainWithIdentifier:[self publicKeyIdentifierForCurrentUser]];
}

- (BOOL)privateKeyExistsForCurrentUser {
    NSAssert([PFUser currentUser] != nil, @"Current user must not be nil.");
    NSString *identifier = [self privateKeyIdentifierForCurrentUser];
    return [KeychainWrapper dataFromMatchingIdentifier:identifier] != nil;
}

- (NSData *)encrypt:(NSString *)plaintext usingPublicKey:(NSData *)publicKey {
    return [LibgcryptWrapper encrypt:plaintext usingPublicKey:publicKey];
}

- (NSString *)decrypt:(NSData *)ciphertext {
    NSString *identifier = [self privateKeyIdentifierForCurrentUser];
    NSData *privateKey = [KeychainWrapper dataFromMatchingIdentifier:identifier];
    
    return [LibgcryptWrapper decrypt:ciphertext usingPrivateKey:privateKey];
}

- (BOOL)testEncryption {
    NSData *publicKey = [self publicKeyForCurrentUser];
    NSData *ciphertext = [self encrypt:ENCRYPTION_TEST_STRING usingPublicKey:publicKey];
    NSString *plaintext = [self decrypt:ciphertext];
    
    return [ENCRYPTION_TEST_STRING isEqualToString:plaintext];
}

#pragma mark - Private Methods

- (NSData *)generateKeyPair {
    NSData *keypair = [LibgcryptWrapper generateKeypair];
    NSData *publicKey = [LibgcryptWrapper getPublicKeyFromKeypair:keypair];
    NSData *privateKey = [LibgcryptWrapper getPrivateKeyFromKeypair:keypair];
    
    // store the keys in the keychain
    [KeychainWrapper createKeychainValueData:privateKey forIdentifier:[self privateKeyIdentifierForCurrentUser]];
    [KeychainWrapper createKeychainValueData:publicKey forIdentifier:[self publicKeyIdentifierForCurrentUser]];
    
    return publicKey;
}

- (NSString *)publicKeyIdentifierForCurrentUser {
    return [NSString stringWithFormat:@"%@.%@", PUBLIC_KEY, [PFUser currentUser].objectId];
}

- (NSString *)privateKeyIdentifierForCurrentUser {
    return [NSString stringWithFormat:@"%@.%@", PRIVATE_KEY, [PFUser currentUser].objectId];
}

@end
