//
//  ChannelInfoPanel.m
//  Comms
//
//  Created by Anthony Picciano on 2/6/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ChannelInfoPanel.h"
#import "Constants.h"

@interface ChannelInfoPanel ()

@end

static const DDLogLevel ddLogLevel = DDLogLevelError;

@implementation ChannelInfoPanel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentView = [[[NSBundle mainBundle]
                             loadNibNamed:@"ChannelInfoPanelContents"
                             owner:self options:nil]
                            firstObject];
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview {
    //
}

- (IBAction)toggleSubscribeButton:(id)sender {
    DDLogDebug(@"toggleSubscribeButton:");
    UISwitch *subscribedSwitch = (UISwitch *)sender;
    if (self.delegate && [self.delegate respondsToSelector:@selector(setSubscribed:)]) {
        [self.delegate performSelector:@selector(setSubscribed:) withObject:[NSNumber numberWithBool:subscribedSwitch.on]];
    }
}

- (IBAction)postMessage:(id)sender {
    DDLogDebug(@"postMessage:");
    if (self.delegate && [self.delegate respondsToSelector:@selector(postMessage)]) {
        [self.delegate performSelector:@selector(postMessage) withObject:nil];
    }
}

- (void)layoutSubviews {
    self.contentView.frame = self.bounds;
}

@end
