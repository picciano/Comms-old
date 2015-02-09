//
//  ChannelViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ChannelViewController.h"
#import "ChannelInfoPanel.h"
#import "PostMessageViewController.h"
#import "Constants.h"

@interface ChannelViewController ()

@property (weak, nonatomic) IBOutlet ChannelInfoPanel *channelInfoPanel;

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation ChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.channel objectForKey:OBJECT_KEY_NAME];
    [self loadSubscriptionStatus];
}

- (void)loadSubscriptionStatus {
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [query whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
    [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (error) {
            DDLogError(@"Error loading subscription: %@", error);
        } else {
            self.channelInfoPanel.subscribedSwitch.on = YES;
        }
    }];
}

- (void)setSubscribed:(NSNumber *)subscribed {
    BOOL on = [subscribed boolValue];
    if (on) {
        PFObject *subscription = [PFObject objectWithClassName:OBJECT_TYPE_SUBSCRIPTION];
        [subscription setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
        [subscription setObject:self.channel forKey:OBJECT_KEY_CHANNEL];
        [subscription saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:SUBSCRIPTION_CHANGE_NOTIFICATION object:self];
        }];
    } else {
        PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
        [query whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
        [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (error) {
                DDLogError(@"Error loading subscription: %@", error);
            } else {
                [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:SUBSCRIPTION_CHANGE_NOTIFICATION object:self];
                }];
            }
        }];
    }
}

- (void)postMessage {
    UIViewController *viewController = [[PostMessageViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
