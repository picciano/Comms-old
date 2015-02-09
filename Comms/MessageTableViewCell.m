//
//  MessageTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/9/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "MessageTableViewCell.h"
#import "Constants.h"

@implementation MessageTableViewCell

- (void)setMessage:(PFObject *)message {
    _message = message;
    
    self.textLabel.text = [self.message objectForKey:OBJECT_KEY_TEXT];
}

@end
