//
//  ChannelTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/6/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ChannelTableViewCell.h"
#import "Constants.h"

@implementation ChannelTableViewCell

- (void)setChannel:(PFObject *)channel {
    _channel = channel;
    self.textLabel.text = [self.channel objectForKey:OBJECT_KEY_NAME];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
