//
//  ViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ViewController.h"
#import "AccountViewController.h"
#import "ChannelTableViewCell.h"
#import "ChannelViewController.h"
#import "Constants.h"

#include <libkern/OSAtomic.h>

#define SUBSCRIBED_CHANNELS     @"Subscribed Channels"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet AccountPanel *accountPanel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong) NSMutableDictionary *channels;
@property (strong) NSMutableArray *groupNames;

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;
static NSString *kChannelReuseIdentifier = @"kChannelReuseIdentifier";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [AppInfoManager bundleName];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ChannelTableViewCell"bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kChannelReuseIdentifier];
    
    self.channels = [NSMutableDictionary dictionaryWithCapacity:3];
    self.groupNames = [NSMutableArray arrayWithCapacity:3];
    
    [self loadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSubscribedChannels) name:SUBSCRIPTION_CHANGE_NOTIFICATION object:nil];
}

#pragma mark - data loading

- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static volatile int32_t NumberOfCallsToSetVisible = 0;
    int32_t newValue = OSAtomicAdd32((setVisible ? +1 : -1), &NumberOfCallsToSetVisible);
    
    NSAssert(newValue >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(newValue > 0)];
}

- (void)loadData {
    [self.groupNames addObject:SUBSCRIBED_CHANNELS];
    [self loadSubscribedChannels];
    
    [self setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *groupsQuery = [PFQuery queryWithClassName:OBJECT_TYPE_GROUP];
    [groupsQuery orderByAscending:OBJECT_KEY_ORDER];
    [groupsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [self setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            DDLogError(@"Error loading data: %@", error);
        } else {
            for (PFObject *group in objects) {
                DDLogDebug(@"Group name: %@", [group objectForKey:OBJECT_KEY_NAME]);
                [self.groupNames addObject:[group objectForKey:OBJECT_KEY_NAME]];
                [self loadChannelsInGroup:group];
            }
        }
    }];
}

- (void)loadSubscribedChannels {
    [self setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *subscriptionQuery = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [subscriptionQuery whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_CHANNEL];
    [query whereKey:OBJECT_KEY_OBJECT_ID matchesKey:OBJECT_KEY_CHANNEL_ID inQuery:subscriptionQuery];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [self setNetworkActivityIndicatorVisible:NO];
        if (error) {
            DDLogError(@"Error loading data: %@", error);
        } else {
            self.channels[SUBSCRIBED_CHANNELS] = objects;
            [self.tableView reloadData];
        }
    }];
}

- (void)loadChannelsInGroup:(PFObject *)group {
    [self setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *channelQuery = [PFQuery queryWithClassName:OBJECT_TYPE_CHANNEL];
    [channelQuery whereKey:OBJECT_KEY_GROUP equalTo:group];
    [channelQuery whereKey:OBJECT_KEY_DISABLED equalTo:@NO];
    [channelQuery orderByAscending:OBJECT_KEY_NAME];
    [channelQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [self setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            DDLogError(@"Error loading data: %@", error);
        } else {
            self.channels[[group objectForKey:OBJECT_KEY_NAME]] = objects;
            [self.tableView reloadData];
        }
    }];
}

- (PFObject *)channelAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *channels = self.channels[self.groupNames[indexPath.section]];
    PFObject *channel = channels[indexPath.row];
    
    return channel;
}

#pragma mark - navigation

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
    return self.channels.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *channels = self.channels[self.groupNames[section]];
    return channels.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.groupNames[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChannelTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kChannelReuseIdentifier forIndexPath:indexPath];
    
    cell.channel = [self channelAtIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChannelViewController *viewController = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
    viewController.channel = [self channelAtIndexPath:indexPath];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
