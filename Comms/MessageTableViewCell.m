//
//  MessageTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/9/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "MessageTableViewCell.h"
#import "PFObject+DateFormat.h"
#import "SecurityService.h"
#import "Constants.h"

@interface MessageTableViewCell ()

@property (strong, nonatomic) NSString *messageText;

@end

@implementation MessageTableViewCell

- (void)drawRect:(CGRect)rect {
    NSString *date = [self.message createdAtWithDateFormat:NSDateFormatterMediumStyle timeFormat:NSDateFormatterShortStyle];
    BOOL locked = ([[self.message objectForKey:OBJECT_KEY_ENCRYPTED] boolValue]);
    PFUser *sender = [self.message objectForKey:OBJECT_KEY_USER];
    
    [StyleKit drawMessageBlockWithFrame:self.bounds
                               isLocked:locked
                         senderUsername:sender.username
                              createdAt:date
                                message:self.messageText];
}

- (void)setMessage:(PFObject *)message {
    _message = message;
    
    if ([[self.message objectForKey:OBJECT_KEY_ENCRYPTED] boolValue]) {
        self.messageText = [self decryptedMessage];
    } else {
        self.messageText = [self.message objectForKey:OBJECT_KEY_TEXT];
    }
    
    [self setNeedsDisplay];
}

- (NSString *)decryptedMessage {
    return [[SecurityService sharedSecurityService] decrypt:[self.message objectForKey:OBJECT_KEY_ENCRYPTED_DATA]];
}

+ (CGFloat)heightForMessage:(PFObject *)message frame:(CGRect)frame {
    
    NSString *messageText;
    
    if ([[message objectForKey:OBJECT_KEY_ENCRYPTED] boolValue]) {
        messageText = [[SecurityService sharedSecurityService] decrypt:[message objectForKey:OBJECT_KEY_ENCRYPTED_DATA]];
    } else {
        messageText = [message objectForKey:OBJECT_KEY_TEXT];
    }
    
    //// Message Text Drawing
    CGRect messageTextRect = CGRectMake(CGRectGetMinX(frame) + 5, CGRectGetMinY(frame) + 25, CGRectGetWidth(frame) - 10, CGRectGetHeight(frame) - 25);
    NSMutableParagraphStyle* messageTextStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
    messageTextStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary* messageTextFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"TrebuchetMS" size: UIFont.smallSystemFontSize], NSForegroundColorAttributeName: StyleKit.commsBlue, NSParagraphStyleAttributeName: messageTextStyle};
    
    CGFloat messageTextTextHeight = [messageText boundingRectWithSize: CGSizeMake(messageTextRect.size.width, INFINITY)  options: NSStringDrawingUsesLineFragmentOrigin attributes: messageTextFontAttributes context: nil].size.height;
    
    return messageTextTextHeight + 30;
}

@end
