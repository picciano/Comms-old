//
//  ProPanel.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ProPanel.h"
#import "InAppPurchaseViewController.h"
#import "CommsIAPHelper.h"
#import "Constants.h"

@interface ProPanel ()

@property (weak, nonatomic) IBOutlet UIButton *hiddenChannelButton;

#ifndef PRO
@property (weak, nonatomic) IBOutlet UIButton *manageSubscriptionsButton;
@property (weak, nonatomic) IBOutlet UIButton *getProFeaturesButton;
#endif

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplay) name:PRODUCT_PURCHASED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)updateDisplay {
    self.hiddenChannelButton.enabled = ([PFUser currentUser] != nil);
    
#ifndef PRO
    BOOL noSubscription = ([[CommsIAPHelper sharedInstance] daysRemainingOnSubscription] == 0);
    self.hiddenChannelButton.hidden = noSubscription;
    self.manageSubscriptionsButton.hidden = noSubscription;
    self.getProFeaturesButton.hidden = !noSubscription;
#endif
    
}

- (IBAction)createOrJoinHiddenChannel:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(showHiddenChannelDialog:)]) {
        [self.delegate performSelector:@selector(showHiddenChannelDialog:) withObject:self];
    }
}

- (IBAction)manageSubscriptions:(id)sender {
    UIViewController *viewController = [[InAppPurchaseViewController alloc] initWithNibName:nil bundle:nil];
    [((UIViewController *)self.delegate).navigationController pushViewController:viewController animated:YES];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateDisplay];
    self.contentView.frame = self.bounds;
}

@end
