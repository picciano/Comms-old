//
//  Message.m
//  Comms
//
//  Created by Anthony Picciano on 2/27/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "Message.h"
#import "Constants.h"
#import "PFObject+DateFormat.h"
#import "SecurityService.h"

@interface Message ()

@property (strong, nonatomic) NSString *text;

@end

@implementation Message

- (instancetype)initWithObject:(PFObject *)object {
    self = [super init];
    if (self) {
        self.object = object;
    }
    return self;
}

+ (instancetype)messageWithObject:(PFObject *)object {
    return [[Message alloc] initWithObject:object];
}

- (BOOL)encrypted {
    return [[self.object objectForKey:OBJECT_KEY_ENCRYPTED] boolValue];
}

- (NSString *)createdAt {
    return [self.object createdAtWithDateFormat:NSDateFormatterMediumStyle timeFormat:NSDateFormatterShortStyle];
}

- (NSString *)senderUsername {
    PFUser *sender = [self.object objectForKey:OBJECT_KEY_USER];
    return sender?sender.username:@"[deleted user]";
}

- (NSString *)text {
    if (!_text) {
        if ([[self.object objectForKey:OBJECT_KEY_ENCRYPTED] boolValue]) {
            self.text = [self decryptedMessage];
        } else {
            self.text = [self.object objectForKey:OBJECT_KEY_TEXT];
        }
    }
    
    return _text;
}

- (NSString *)decryptedMessage {
    return [[SecurityService sharedSecurityService] decrypt:[self.object objectForKey:OBJECT_KEY_ENCRYPTED_DATA]];
}

+ (CGFloat)heightForMessage:(Message *)message frame:(CGRect)frame {
    CGRect messageTextRect = CGRectMake(CGRectGetMinX(frame) + 5, CGRectGetMinY(frame) + 25, CGRectGetWidth(frame) - 10, CGRectGetHeight(frame) - 25);
    NSMutableParagraphStyle* messageTextStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
    messageTextStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary* messageTextFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"TrebuchetMS" size: UIFont.smallSystemFontSize], NSForegroundColorAttributeName: StyleKit.commsBlue, NSParagraphStyleAttributeName: messageTextStyle};
    
    CGFloat messageTextTextHeight = [message.text boundingRectWithSize: CGSizeMake(messageTextRect.size.width, INFINITY)  options: NSStringDrawingUsesLineFragmentOrigin attributes: messageTextFontAttributes context: nil].size.height;
    
    return messageTextTextHeight + 30;
}

@end
