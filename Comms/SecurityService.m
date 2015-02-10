//
//  SecurityService.m
//  Comms
//
//  Created by Anthony Picciano on 2/10/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "SecurityService.h"
#import "SecKeyWrapper.h"
#import "Constants.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

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

- (NSData *)getPublicKeyBits {
    SecKeyWrapper *wrapper = [self wrapper];
    
    if (![wrapper getPublicKeyBits]) {
        [wrapper generateKeyPair:SECURITY_SERVICE_BIT_LENGTH];
    }
    
    return [wrapper getPublicKeyBits];
}

- (void)deleteKeyPair {
    [[self wrapper] deleteAsymmetricKeys];
}

- (SecKeyWrapper *)wrapper {
    
    if (![PFUser currentUser]) {
        [NSException raise:@"Invalid user exception" format:@"User must be logged in."];
    }
    
    SecKeyWrapper *wrapper = [SecKeyWrapper sharedWrapper];
    
    if ([PFUser currentUser]) {
        NSString *username = [PFUser currentUser].username;
        
        NSString *publicKeyIdentifier = [NSString stringWithFormat:@"%s%s%@", kPublicKeyTag, ".", username];
        NSData *publicTag = [publicKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
        [wrapper setPublicTag:publicTag];
        
        NSString *privateKeyIdentifier = [NSString stringWithFormat:@"%s%s%@", kPrivateKeyTag, ".", username];
        NSData *privateTag = [privateKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
        [wrapper setPrivateTag:privateTag];
    }
    
    return wrapper;
}

@end
