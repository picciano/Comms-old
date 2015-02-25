//
//  KeychainWrapper.h
//  Comms
//
//  Created by Anthony Picciano on 2/24/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeychainWrapper : NSObject

// Generic exposed method to search the keychain for a given value. Limit one result per search.
+ (NSData *)dataFromMatchingIdentifier:(NSString *)identifier;

// Calls dataFromMatchingIdentifier: and converts to a string value.
+ (NSString *)stringFromMatchingIdentifier:(NSString *)identifier;

// Default initializer to store a value in the keychain.
// Associated properties are handled for you - setting Data Protection Access, Company Identifer (to uniquely identify string, etc).
+ (BOOL)createKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier;
+ (BOOL)createKeychainValueData:(NSData *)valueData forIdentifier:(NSString *)identifier;

// Updates a value in the keychain. If you try to set the value with createKeychainValue: and it already exists,
// this method is called instead to update the value in place.
+ (BOOL)updateKeychainValue:(NSString *)value forIdentifier:(NSString *)identifier;
+ (BOOL)updateKeychainValueData:(NSData *)valueData forIdentifier:(NSString *)identifier;

// Delete a value in the keychain.
+ (BOOL)deleteItemFromKeychainWithIdentifier:(NSString *)identifier;

@end
