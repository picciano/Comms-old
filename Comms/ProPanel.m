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
        self.backgroundColor = [StyleKit commsDeepGreen];
    }
    return self;
}

- (void)layoutSubviews {
    self.contentView.frame = self.bounds;
}

@end
