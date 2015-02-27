//
//  MessageTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/9/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "MessageTableViewCell.h"
#import "StyleKit.h"
#import "Message.h"

@implementation MessageTableViewCell

- (void)drawRect:(CGRect)rect {
    [StyleKit drawMessageBlockWithFrame:self.bounds
                               isLocked:self.message.encrypted
                         senderUsername:self.message.senderUsername
                              createdAt:self.message.createdAt
                                message:self.message.text];
}

- (void)setMessage:(Message *)message {
    _message = message;
    [self setNeedsDisplay];
}

@end
