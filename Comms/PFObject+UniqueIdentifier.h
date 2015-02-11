//
//  PFObject+UniqueIdentifier.h
//  Comms
//
//  Created by Anthony Picciano on 2/11/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Parse/Parse.h>

#define USERNAME_KEY        @"username"
#define USERNAME_ANONYMOUS  @"Anonymous"

@interface PFObject (UniqueIdentifier)

- (NSString *)uniqueIdentifier;

@end
