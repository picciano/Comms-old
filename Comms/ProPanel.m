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
    }
    return self;
}

- (void)didMoveToSuperview {
//    self.usernameLabel.text = ([PFUser currentUser])?[PFUser currentUser].username:@"Not Logged In";
}

- (void)layoutSubviews {
    self.contentView.frame = self.bounds;
}

@end