//
//  PFObject+UniqueIdentifier.m
//  Comms
//
//  Created by Anthony Picciano on 2/11/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "PFObject+UniqueIdentifier.h"

#define UID_FORMAT          @"%@.%f"

@implementation PFObject (UniqueIdentifier)

- (NSString *)uniqueIdentifier {
    
    NSTimeInterval secs = [self.createdAt timeIntervalSinceReferenceDate];
    NSString *username = ([self objectForKey:USERNAME_KEY])?[self objectForKey:USERNAME_KEY]:USERNAME_ANONYMOUS;
    
    NSString *uid = [NSString stringWithFormat:UID_FORMAT, username, secs];
    
    return uid;
}

@end
