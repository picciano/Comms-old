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

@property (assign, nonatomic) IBOutlet UILabel *usernameLabel;

@end

@implementation AccountPanel

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.contentView = [[[NSBundle mainBundle]
                             loadNibNamed:@"AccountPanelContents"
                             owner:self options:nil]
                            firstObject];
        [self addSubview:self.contentView];
        self.backgroundColor = [StyleKit commsDeepGreen];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplay) name:CURRENT_USER_CHANGE_NOTIFICATION object:nil];
    }
    return self;
}

- (void)didMoveToSuperview {
    [self updateDisplay];
}

- (void)updateDisplay {
    self.usernameLabel.text = ([PFUser currentUser])?[PFUser currentUser].username:@"Not Logged In";
}

- (IBAction)accountView:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigateToAccountView:)]) {
        [self.delegate performSelector:@selector(navigateToAccountView:) withObject:self];
    }
}

- (IBAction)infoView:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(navigateToInfoView:)]) {
        [self.delegate performSelector:@selector(navigateToInfoView:) withObject:self];
    }
}

- (void)layoutSubviews {
    self.contentView.frame = self.bounds;
}

@end
