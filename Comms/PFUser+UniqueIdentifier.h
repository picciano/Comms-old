//
//  PFUser+UniqueIdentifier.h
//  Comms
//
//  Created by Anthony Picciano on 2/14/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFUser (UniqueIdentifier)

- (NSString *)uniqueIdentifier;

@end
