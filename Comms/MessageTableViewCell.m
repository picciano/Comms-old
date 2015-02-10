//
//  MessageTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/9/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "MessageTableViewCell.h"
#import "PFObject+DateFormat.h"
#import "Constants.h"

@implementation MessageTableViewCell

- (void)drawRect:(CGRect)rect {
    NSString *date = [self.message createdAtWithDateFormat:NSDateFormatterMediumStyle timeFormat:NSDateFormatterShortStyle];
    BOOL locked = [self.message objectForKey:OBJECT_KEY_RECIPIENT];
    
    [StyleKit drawMessageBlockWithFrame:self.bounds isLocked:locked senderUsername:@"Picciano" createdAt:[NSString stringWithFormat:@"%@", date] message:[self.message objectForKey:OBJECT_KEY_TEXT]];
}

+ (CGFloat)heightForMessage:(PFObject *)messageObject frame:(CGRect)frame {
    
    NSString *message = [messageObject objectForKey:OBJECT_KEY_TEXT];
    
    //// Message Text Drawing
    CGRect messageTextRect = CGRectMake(CGRectGetMinX(frame) + 5, CGRectGetMinY(frame) + 25, CGRectGetWidth(frame) - 10, CGRectGetHeight(frame) - 25);
    NSMutableParagraphStyle* messageTextStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
    messageTextStyle.alignment = NSTextAlignmentLeft;
    
    NSDictionary* messageTextFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"TrebuchetMS" size: UIFont.smallSystemFontSize], NSForegroundColorAttributeName: StyleKit.commsBlue, NSParagraphStyleAttributeName: messageTextStyle};
    
    CGFloat messageTextTextHeight = [message boundingRectWithSize: CGSizeMake(messageTextRect.size.width, INFINITY)  options: NSStringDrawingUsesLineFragmentOrigin attributes: messageTextFontAttributes context: nil].size.height;
    
    return messageTextTextHeight + 30;
}

@end
