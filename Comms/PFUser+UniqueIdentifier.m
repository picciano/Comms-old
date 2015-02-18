//
//  PFUser+UniqueIdentifier.m
//  Comms
//
//  Created by Anthony Picciano on 2/14/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "PFUser+UniqueIdentifier.h"

@implementation PFUser (UniqueIdentifier)

- (NSString *)uniqueIdentifier {
    NSString *objectId = self.objectId;
    NSTimeInterval updateAt = [self.updatedAt timeIntervalSinceReferenceDate];
    
    NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@.%f", objectId, updateAt];
    
    return uniqueIdentifier;
}

@end
