//
//  ViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ViewController.h"
#import "AccountViewController.h"
#import "ChannelViewController.h"
#import "Constants.h"

@interface ViewController ()

@end

//static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [AppInfoManager bundleName];
}

- (IBAction)channel:(id)sender {
    UIViewController *viewController = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)account:(id)sender {
    UIViewController *viewController = [[AccountViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
