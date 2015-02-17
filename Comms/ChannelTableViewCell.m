//
//  ChannelTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/6/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ChannelTableViewCell.h"
#import "Constants.h"
#import "StyleKit.h"

@implementation ChannelTableViewCell

- (void)setChannel:(PFObject *)channel {
    _channel = channel;
    self.textLabel.text = [self.channel objectForKey:OBJECT_KEY_NAME];
    
    BOOL hidden = [[self.channel objectForKey:OBJECT_KEY_HIDDEN] boolValue];
    if (hidden) {
        self.imageView.image = [StyleKit imageOfChannelLock];
    } else {
        self.imageView.image = nil;
    }
}

@end
