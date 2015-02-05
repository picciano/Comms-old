//
//  AccountPanel.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "AccountPanel.h"
#import "Constants.h"

@interface AccountPanel ()

@property (assign, nonatomic) IBOutlet UILabel *accountNameLabel;

@end

//static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation AccountPanel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentView = [[[NSBundle mainBundle]
                             loadNibNamed:@"AccountPanelContents"
                             owner:self options:nil]
                            firstObject];
        [self addSubview:self.contentView];
    }
    return self;
}

- (void)didMoveToSuperview {
    self.accountNameLabel.text = ([PFUser currentUser])?[PFUser currentUser].username:@"Not Logged In";
}

- (IBAction)accountView:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigateToAccountView:)]) {
        [self.delegate performSelector:@selector(navigateToAccountView:) withObject:self];
    }
}

- (void)layoutSubviews {
    self.contentView.frame = self.bounds;
}

@end
