//
//  ViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ViewController.h"
#import "AccountViewController.h"
#import "GroupViewController.h"
#import "GroupTableViewCell.h"
#import "ChannelTableViewCell.h"
#import "ChannelViewController.h"
#import "Constants.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet AccountPanel *accountPanel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

//static const DDLogLevel ddLogLevel = DDLogLevelDebug;
static NSString *kGroupReuseIdentifier = @"kGroupReuseIdentifier";
static NSString *kChannelReuseIdentifier = @"kChannelReuseIdentifier";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [AppInfoManager bundleName];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"GroupTableViewCell"bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kGroupReuseIdentifier];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ChannelTableViewCell"bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kChannelReuseIdentifier];
}

#pragma mark - navigation

- (IBAction)viewGroup:(id)sender {
    UIViewController *viewController = [[GroupViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)viewChannel:(id)sender {
    UIViewController *viewController = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)navigateToAccountView:(id)sender {
    UIViewController *viewController = [[AccountViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - tableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Subscribed Channels";
            break;
            
        case 1:
            return @"Group Categories";
            break;
            
        default:
            return nil;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            return [self tableView:tableView channelTableViewCellAtIndexPath:indexPath];
            break;
            
        case 1:
            return [self tableView:tableView groupTableViewCellAtIndexPath:indexPath];
            break;
            
        default:
            return nil;
            break;
    }
}

- (ChannelTableViewCell *)tableView:(UITableView *)tableView channelTableViewCellAtIndexPath:(NSIndexPath *)indexPath {
    ChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kChannelReuseIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Channel Name";
    
    return cell;
}

- (GroupTableViewCell *)tableView:(UITableView *)tableView groupTableViewCellAtIndexPath:(NSIndexPath *)indexPath {
    GroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGroupReuseIdentifier forIndexPath:indexPath];
    cell.textLabel.text = @"Group name";
    
    return cell;
}

@end
