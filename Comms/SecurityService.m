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

- (NSString *)decrypt:(NSData *)ciphertext {
    SecKeyRef privateKey = [[self wrapper] getPrivateKeyRef];
    NSString *plaintext = [self decrypt:ciphertext usingPrivateKey:privateKey];
    
    return plaintext;
}

- (NSData *)encrypt:(NSString *)plaintext usingPublicKeyBits:(NSData *)publicKeyBits for:(NSString *)username {
    NSString *peerName = [NSString stringWithFormat:@"%s.%@", kPublicKeyTag, username];
    SecKeyRef publicKey = [[self wrapper] getPublicKeyRefForPeer:peerName];
    
    if (!publicKey) {
        DDLogDebug(@"Peer not found. Adding peer public key.");
        publicKey = [[self wrapper] addPeerPublicKey:peerName keyBits:publicKeyBits];
    }
    
    return [self encrypt:plaintext usingPublicKey:publicKey];
}

- (NSData *)encrypt:(NSString *)plaintext usingPublicKey:(SecKeyRef)publicKey {
    NSCParameterAssert(plaintext.length > 0);
    NSCParameterAssert(publicKey != NULL);
    
    OSStatus status = noErr;
    NSData *dataToEncrypt = [plaintext dataUsingEncoding:NSUTF8StringEncoding];
    const uint8_t *bytesToEncrypt = dataToEncrypt.bytes;
    
    size_t cipherBufferSize = SecKeyGetBlockSize(publicKey);
    NSCAssert(cipherBufferSize > 11, @"block size is too small: %zd", cipherBufferSize);
    
    const size_t inputBlockSize = cipherBufferSize - 11; // since we'll use PKCS1 padding
    uint8_t *cipherBuffer = malloc(cipherBufferSize);
    
    NSMutableData *accumulator = [[NSMutableData alloc] init];
    
    @try {
        
        for (size_t block = 0; block * inputBlockSize < dataToEncrypt.length; block++) {
            size_t blockOffset = block * inputBlockSize;
            const uint8_t *chunkToEncrypt = (bytesToEncrypt + block * inputBlockSize);
            const size_t remainingSize = dataToEncrypt.length - blockOffset;
            const size_t subsize = remainingSize < inputBlockSize ? remainingSize : inputBlockSize;
            
            size_t actualOutputSize = cipherBufferSize;
            
            status = SecKeyEncrypt(publicKey,
                                            kSecPaddingPKCS1,
                                            chunkToEncrypt,
                                            subsize,
                                            cipherBuffer,
                                            &actualOutputSize);
            
            if (status != noErr) {
                NSLog(@"Cannot encrypt data, last SecKeyEncrypt status: %d", (int)status);
                return nil;
            }
            
            [accumulator appendBytes:cipherBuffer length:actualOutputSize];
        }
        
        return [accumulator copy];
    }
    @finally {
        free(cipherBuffer);
    }
}

- (NSString *)decrypt:(NSData *)ciphertext usingPrivateKey:(SecKeyRef)privateKey {
    OSStatus status = noErr;
    
    size_t cipherBufferSize = [ciphertext length];
    uint8_t *cipherBuffer = (uint8_t *)[ciphertext bytes];
    
    size_t plainBufferSize;
    uint8_t *plainBuffer;
    
    plainBufferSize = SecKeyGetBlockSize(privateKey);
    plainBuffer = malloc(plainBufferSize);
    
    NSMutableData *accumulator = [[NSMutableData alloc] init];
    
    for (size_t block = 0; block * plainBufferSize < cipherBufferSize; block++) {
        size_t blockOffset = block * plainBufferSize;
        const uint8_t *chunkToDecrypt = (cipherBuffer + block * plainBufferSize);
        const size_t remainingSize = cipherBufferSize - blockOffset;
        const size_t subsize = remainingSize < plainBufferSize ? remainingSize : plainBufferSize;
        
        size_t actualOutputSize;
        
        status = SecKeyDecrypt(privateKey,
                               kSecPaddingPKCS1,
                               chunkToDecrypt,
                               subsize,
                               plainBuffer,
                               &actualOutputSize);
        
        if (status != noErr) {
            DDLogError(@"Cannot decrypt data, last SecKeyEncrypt status: %d", (int)status);
            return nil;
        }
        
        [accumulator appendBytes:plainBuffer length:actualOutputSize];
    }
    
    return [[NSString alloc] initWithData:accumulator encoding:NSUTF8StringEncoding];
}

- (SecKeyWrapper *)wrapper {
    NSCParameterAssert([PFUser currentUser] != nil);
    
    SecKeyWrapper *wrapper = [SecKeyWrapper sharedWrapper];
    
    if ([PFUser currentUser]) {
        NSString *username = [PFUser currentUser].username;
        
        NSString *publicKeyIdentifier = [NSString stringWithFormat:@"%s.%@", kPublicKeyTag, username];
        NSData *publicTag = [publicKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
        [wrapper setPublicTag:publicTag];
        
        NSString *privateKeyIdentifier = [NSString stringWithFormat:@"%s.%@", kPrivateKeyTag, username];
        NSData *privateTag = [privateKeyIdentifier dataUsingEncoding:NSUTF8StringEncoding];
        [wrapper setPrivateTag:privateTag];
    }
    
    return wrapper;
}

@end
