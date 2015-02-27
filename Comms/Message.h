//
//  Message.h
//  Comms
//
//  Created by Anthony Picciano on 2/27/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PFObject;

@interface Message : NSObject

@property (strong, nonatomic) PFObject *object;

@property (readonly, nonatomic) BOOL encrypted;
@property (readonly, nonatomic) NSString *createdAt;
@property (readonly, nonatomic) NSString *senderUsername;
@property (readonly, nonatomic) NSString *text;

- (instancetype)initWithObject:(PFObject *)object;
+ (instancetype)messageWithObject:(PFObject *)object;
+ (CGFloat)heightForMessage:(PFObject *)messageObject frame:(CGRect)frame;

@end
