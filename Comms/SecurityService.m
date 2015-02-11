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

- (NSData *)encrypt:(NSString *)plaintext usingPublicKeyBits:(NSData *)publicKeyBits for:(NSString *)uid {
    NSString *peerName = [NSString stringWithFormat:@"%s.%@", kPublicKeyTag, uid];
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
    size_t inputBufferSize = [plaintext length];
    const uint8_t *bytesToEncrypt = dataToEncrypt.bytes;
    
    size_t cipherBufferSize = SecKeyGetBlockSize(publicKey);
    uint8_t *cipherBuffer = malloc(cipherBufferSize);
    
    NSMutableData *accumulator = [[NSMutableData alloc] init];
    
    @try {
        
        for (size_t block = 0; block * cipherBufferSize < inputBufferSize; block++) {
            size_t blockOffset = block * cipherBufferSize;
            const uint8_t *chunkToEncrypt = (bytesToEncrypt + block * cipherBufferSize);
            const size_t remainingSize = inputBufferSize - blockOffset;
            const size_t subsize = remainingSize < cipherBufferSize ? remainingSize : cipherBufferSize;
            
            size_t actualOutputSize = cipherBufferSize;
            
            status = SecKeyEncrypt(publicKey,
                                            kSecPaddingPKCS1,
                                            chunkToEncrypt,
                                            subsize,
                                            cipherBuffer,
                                            &actualOutputSize);
            
            if (status != noErr) {
                DDLogError(@"Cannot encrypt data, last SecKeyEncrypt status: %d", (int)status);
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
    NSCParameterAssert(ciphertext.length > 0);
    NSCParameterAssert(privateKey != NULL);
    
    OSStatus status = noErr;
    
    size_t cipherBufferSize = [ciphertext length];
    const uint8_t *cipherBuffer = (uint8_t *)[ciphertext bytes];
    
    size_t plainBufferSize = SecKeyGetBlockSize(privateKey);
    uint8_t *plainBuffer = malloc(plainBufferSize);
    
    NSMutableData *accumulator = [[NSMutableData alloc] init];
    
    @try {
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
    @finally {
        free(plainBuffer);
    }
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
