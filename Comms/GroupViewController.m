//
//  GroupViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/6/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "GroupViewController.h"
#import "ChannelViewController.h"

@interface GroupViewController ()

@end

@implementation GroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Group";
}

- (IBAction)viewChannel:(id)sender {
    UIViewController *viewController = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
