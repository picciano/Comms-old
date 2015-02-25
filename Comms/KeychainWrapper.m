//
//  KeychainWrapper.m
//  Comms
//
//  Created by Anthony Picciano on 2/24/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "KeychainWrapper.h"

@implementation KeychainWrapper

+ (NSMutableDictionary *)setupSearchDirectoryForIdentifier:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];
    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    [searchDictionary setObject:bundleIdentifier forKey:(__bridge id)kSecAttrService];
    
    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    
    return searchDictionary;
}

+ (NSData *)dataFromMatchingIdentifier:(NSString *)identifier {
    
    NSMutableDictionary *searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    [searchDictionary setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
    NSData *result = nil;
    CFTypeRef foundDict = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary, &foundDict);
    
    if (status == noErr) {
        result = (__bridge_transfer NSData *)foundDict;
    } else {
        result = nil;
    }
    
    return result;
}

+ (NSString *)stringFromMatchingIdentifier:(NSString *)identifier {
    NSData *valueData = [self dataFromMatchingIdentifier:identifier];
    if (valueData) {
        NSString *value = [[NSString alloc] initWithData:valueData
                                                encoding:NSUTF8StringEncoding];
        return value;
    }
    else {
        return nil;
    }
}

+ (BOOL)createKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier {
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [KeychainWrapper createKeychainValueData:valueData forIdentifier:identifier];
}

+ (BOOL)createKeychainValueData:(NSData *)valueData forIdentifier:(NSString *)identifier {
    NSMutableDictionary *dictionary = [self setupSearchDirectoryForIdentifier:identifier];
    [dictionary setObject:valueData forKey:(__bridge id)kSecValueData];
    
    // Protect the keychain entry so it's only valid when the device is unlocked.
    [dictionary setObject:(__bridge id)kSecAttrAccessibleWhenUnlocked forKey:(__bridge id)kSecAttrAccessible];
    
    // Add.
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    
    // If the addition was successful, return. Otherwise, attempt to update existing key or quit (return NO).
    if (status == errSecSuccess) {
        return YES;
    }
    else if (status == errSecDuplicateItem){
        return [self updateKeychainValueData:valueData forIdentifier:identifier];
    }
    else {
        return NO;
    }
}

+ (BOOL)updateKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier {
    NSData *valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [KeychainWrapper updateKeychainValueData:valueData forIdentifier:identifier];
}

+ (BOOL)updateKeychainValueData:(NSData *)valueData forIdentifier:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    [updateDictionary setObject:valueData forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);
    
    if (status == errSecSuccess) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (BOOL)deleteItemFromKeychainWithIdentifier:(NSString *)identifier {
    NSMutableDictionary *searchDictionary = [self setupSearchDirectoryForIdentifier:identifier];
    CFDictionaryRef dictionary = (__bridge CFDictionaryRef)searchDictionary;
    OSStatus status = SecItemDelete(dictionary);
    
    if (status == errSecSuccess) {
        return YES;
    }
    else {
        return NO;
    }
}

@end
