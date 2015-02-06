//
//  ChannelViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ChannelViewController.h"
#import "PostMessageViewController.h"
#import "Constants.h"

@interface ChannelViewController ()

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation ChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.channel objectForKey:OBJECT_KEY_NAME];
}

- (void)setSubscribed:(NSNumber *)subscribed {
    BOOL on = [subscribed boolValue];
    DDLogDebug(@"%@ %@", on?@"Subscribing to":@"Unsubscribing from", self.title);
}

- (void)postMessage {
    UIViewController *viewController = [[PostMessageViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
