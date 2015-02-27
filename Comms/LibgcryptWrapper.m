//
//  LibgcryptWrapper.m
//  Comms
//
//  Created by Anthony Picciano on 2/23/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "LibgcryptWrapper.h"
#import "CocoaLumberjack.h"
#import <gcrypt/gcrypt.h>

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

@implementation LibgcryptWrapper

//static const char * GENKEY_STRING = "(genkey (rsa (nbits 4:1024)))";
//static const char * GENKEY_STRING = "(genkey (elg (nbits 3:256)))";
static const char * GENKEY_STRING = "(genkey (elg (nbits 3:512)))";
//static const char * GENKEY_STRING = "(genkey (elg (nbits 4:1024)))";
//static const char * GENKEY_STRING = "(genkey (elg (nbits 4:2048)))";
//static const char * GENKEY_STRING = "(genkey (elg (nbits 4:4096)))";
//static const char * GENKEY_STRING = "(genkey (ecc (curve secp521r1) (nbits 3:521)))"; //paranoid mode, not working
static const char * PUBLIC_KEY = "public-key";
static const char * PRIVATE_KEY = "private-key";
static const char * EXPECTED_VERSION = "1.5.3";

+ (void)initialize {
    
    [super initialize];
    
    const char * version = gcry_check_version(EXPECTED_VERSION);
    gcry_control (GCRYCTL_DISABLE_SECMEM, 0);
    gcry_control (GCRYCTL_INITIALIZATION_FINISHED, 0);
    
    DDLogInfo(@"Libgrcypt initialized. Version: %s", version);
}

+ (NSData *)generateKeypair {
    gcry_error_t err = 0;
    gcry_sexp_t params = NULL;
    gcry_sexp_t keypair = NULL;
    
    err = gcry_sexp_build(&params, NULL, GENKEY_STRING);
    if (err) {
        DDLogError(@"gcrypt: failed to create params");
    }
    
    err = gcry_pk_genkey(&keypair, params);
    if (err) {
        DDLogError(@"gcrypt: failed to create key pair");
    }
    
    NSData *result = [LibgcryptWrapper dataFromSexp:keypair];
    
    gcry_sexp_release(params);
    gcry_sexp_release(keypair);
    
    return result;
}

+ (NSData *)getPublicKeyFromKeypair:(NSData *)data {
    gcry_sexp_t keypair = [LibgcryptWrapper sexpFromData:data];
    gcry_sexp_t public_key = [LibgcryptWrapper publicKeyFromKeyPair:keypair];
    
    NSData *key = [LibgcryptWrapper dataFromSexp:public_key];
    
    gcry_sexp_release(keypair);
    gcry_sexp_release(public_key);
    
    return key;
}


+ (NSData *)getPrivateKeyFromKeypair:(NSData *)data {
    gcry_sexp_t keypair = [LibgcryptWrapper sexpFromData:data];
    gcry_sexp_t private_key = [LibgcryptWrapper privateKeyFromKeyPair:keypair];
    
    NSData *key = [LibgcryptWrapper dataFromSexp:private_key];
    
    gcry_sexp_release(keypair);
    gcry_sexp_release(private_key);
    
    return key;
}

+ (NSData *)encrypt:(NSString *)plaintext usingPublicKey:(NSData *)publicKey {
    gcry_sexp_t pkey = [LibgcryptWrapper sexpFromData:publicKey];
    int chunkSize = gcry_pk_get_nbits(pkey) / 8;
    
    if (plaintext.length <= chunkSize) {
        NSData *data = [LibgcryptWrapper encryptChunk:plaintext usingPublicKey:pkey];
        gcry_sexp_release(pkey);
        return data;
    } else {
        __block NSRange range = NSMakeRange(0, chunkSize);
        NSMutableData *data = [NSMutableData data];
        
        while (range.location < plaintext.length) {
            NSString *chunk = [plaintext substringWithRange:range];
            [data appendData:[LibgcryptWrapper encryptChunk:chunk usingPublicKey:pkey]];
            DDLogVerbose(@"chunk: %@", chunk);
            range.location += chunkSize;
            range.length = MIN(chunkSize, plaintext.length - range.location);
        }
        
        gcry_sexp_release(pkey);
        
        return data;
    }
}

+ (NSData *)encryptChunk:(NSString *)plaintext usingPublicKey:(gcry_sexp_t)pkey {
    gcry_error_t err = 0;
    gcry_sexp_t ciph = NULL;
    gcry_sexp_t ptxt = NULL;
    
    err = gcry_sexp_build(&ptxt, NULL, "(data (flags raw) (value %s))", [plaintext UTF8String]);
    if (err) {
        DDLogError(@"gcrypt: failed to create sexp from plaintext");
    }
    
    err = gcry_pk_encrypt(&ciph, ptxt, pkey);
    if (err) {
        DDLogError(@"gcrypt: failed to encrypt");
    }
    
    if (ddLogLevel >= DDLogLevelVerbose) {
        gcry_sexp_dump(ciph);
    }
    
    NSData *data = [LibgcryptWrapper dataFromSexp:ciph];
    
    gcry_sexp_release(ptxt);
    gcry_sexp_release(ciph);
    
    return data;
}

+ (NSString *)decrypt:(NSData *)ciphertext usingPrivateKey:(NSData *)privateKey {
    gcry_sexp_t skey = [LibgcryptWrapper sexpFromData:privateKey];
    
    NSData *delimiter = [NSData dataWithBytes:")))\0" length:4];
    
    NSRange range = [ciphertext rangeOfData:delimiter
                                    options:0
                                      range:NSMakeRange(0, ciphertext.length)];
    size_t body_offset = 0;
    NSMutableString *plaintext = [NSMutableString string];
    
    while (range.location != NSNotFound) {
        size_t body_size = NSMaxRange(range) - body_offset;
        range = NSMakeRange(body_offset, body_size);
        
        NSData *chunk = [ciphertext subdataWithRange:range];
        NSString *decryptedChunk = [LibgcryptWrapper decryptChunk:chunk usingPrivateKey:skey];
        if (decryptedChunk) {
            [plaintext appendString:decryptedChunk];
        }
        
        body_offset += body_size;
        range = [ciphertext rangeOfData:delimiter options:0 range:NSMakeRange(body_offset, ciphertext.length - body_offset)];
    }
    
    gcry_sexp_release(skey);
    
    return plaintext;
}

+ (NSString *)decryptChunk:(NSData *)ciphertext usingPrivateKey:(gcry_sexp_t)skey {
    gcry_error_t err = 0;
    
    gcry_sexp_t ptxt = NULL;
    gcry_sexp_t ciph = [LibgcryptWrapper sexpFromData:ciphertext];
    err = gcry_pk_decrypt(&ptxt, ciph, skey);
    if (err) {
        DDLogError(@"gcrypt: failed to decrypt");
    }
    
    if (ddLogLevel >= DDLogLevelVerbose) {
        gcry_sexp_dump(ptxt);
    }
    
    size_t length = 0;
    const char * plainttext = gcry_sexp_nth_data(ptxt, 0, &length);
    DDLogVerbose(@"plainttext: %s", plainttext);
    
    if (plainttext) {
        NSString *string = [NSString stringWithCString:plainttext encoding:NSUTF8StringEncoding];
        gcry_sexp_release(ptxt);
        return string;
    }
    
    gcry_sexp_release(ptxt);
    
    return nil;
}

+ (NSString *)stringFromKey:(NSData *)key {
    gcry_sexp_t sexp = [LibgcryptWrapper sexpFromData:key];
    
    size_t length = gcry_sexp_sprint(sexp, GCRYSEXP_FMT_ADVANCED, NULL, 0); // Needed to get the length
    char * buffer = (char *)malloc(length);
    
    gcry_sexp_sprint(sexp, GCRYSEXP_FMT_ADVANCED, buffer, length);
    
    NSString *string = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    
    gcry_sexp_release(sexp);
    
    return string;
}

#pragma mark - Private Methods

+ (gcry_sexp_t)publicKeyFromKeyPair:(gcry_sexp_t)keypair {
    return gcry_sexp_find_token(keypair, PUBLIC_KEY, 0);
}

+ (gcry_sexp_t)privateKeyFromKeyPair:(gcry_sexp_t)keypair {
    return gcry_sexp_find_token(keypair, PRIVATE_KEY, 0);
}

+ (gcry_sexp_t)sexpFromData:(NSData *)data {
    gcry_error_t err = 0;
    gcry_sexp_t sexp = NULL;
    err = gcry_sexp_new(&sexp, data.bytes, data.length, 0);
    if (err) {
        DDLogError(@"gcrypt: failed to create sexp from data");
    }
    
    return sexp;
}

+ (NSData *)dataFromSexp:(gcry_sexp_t)sexp {
    size_t length = gcry_sexp_sprint(sexp, GCRYSEXP_FMT_CANON, NULL, 0); // Needed to get the length
    char * buffer = (char *)malloc(length);
    
    gcry_sexp_sprint(sexp, GCRYSEXP_FMT_CANON, buffer, length);
    NSData *result = [NSData dataWithBytes:buffer length:length];
    
    return result;
}

@end
