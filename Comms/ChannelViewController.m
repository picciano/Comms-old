//
//  ChannelViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ChannelViewController.h"
#import "NewMessageViewController.h"
#import "Constants.h"

@interface ChannelViewController ()

@end

@implementation ChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.channel objectForKey:OBJECT_KEY_NAME];
}

- (IBAction)newMessage:(id)sender {
    UIViewController *viewController = [[NewMessageViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
