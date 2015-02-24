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

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation LibgcryptWrapper

//static const char * GENKEY_STRING = "(genkey (ecc (curve secp256r1) (nbits 3:256)))";
static const char * GENKEY_STRING = "(genkey (ecc (curve secp521r1) (nbits 3:521)))"; //paranoid mode
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
    gcry_sexp_t params;
    gcry_sexp_t keypair;
    
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
    
    return [LibgcryptWrapper dataFromSexp:public_key];
}


+ (NSData *)getPrivateKeyFromKeypair:(NSData *)data {
    gcry_sexp_t keypair = [LibgcryptWrapper sexpFromData:data];
    gcry_sexp_t private_key = [LibgcryptWrapper privateKeyFromKeyPair:keypair];
    
    return [LibgcryptWrapper dataFromSexp:private_key];
}

+ (gcry_sexp_t)publicKeyFromKeyPair:(gcry_sexp_t)keypair {
    return gcry_sexp_find_token(keypair, PUBLIC_KEY, 0);
}

+ (gcry_sexp_t)privateKeyFromKeyPair:(gcry_sexp_t)keypair {
    return gcry_sexp_find_token(keypair, PRIVATE_KEY, 0);
}

+ (gcry_sexp_t)sexpFromData:(NSData *)data {
    gcry_error_t err = 0;
    gcry_sexp_t sexp;
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
