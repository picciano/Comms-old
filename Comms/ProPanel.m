//
//  ProPanel.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ProPanel.h"
#import "Constants.h"

@interface ProPanel ()

@property (weak, nonatomic) IBOutlet UIButton *hiddenChannelButton;

@end

//static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation ProPanel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        NSString *contentViewName = ([AppInfoManager isProVersion])?@"ProPanelContents":@"ProPanelPromotion";
        self.contentView = [[[NSBundle mainBundle]
                             loadNibNamed:contentViewName
                             owner:self options:nil]
                            firstObject];
        [self addSubview:self.contentView];
        self.backgroundColor = [StyleKit commsDeepGreen];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplay) name:CURRENT_USER_CHANGE_NOTIFICATION object:nil];
    }
    return self;
}

- (void)updateDisplay {
    self.hiddenChannelButton.enabled = ([PFUser currentUser] != nil);
}

- (IBAction)createOrJoinHiddenChannel:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showHiddenChannelDialog:)]) {
        [self.delegate performSelector:@selector(showHiddenChannelDialog:) withObject:self];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateDisplay];
    self.contentView.frame = self.bounds;
}

@end
