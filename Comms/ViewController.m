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
}

#pragma mark - data loading

- (void)setNetworkActivityIndicatorVisible:(BOOL)setVisible {
    static volatile int32_t NumberOfCallsToSetVisible = 0;
    int32_t newValue = OSAtomicAdd32((setVisible ? +1 : -1), &NumberOfCallsToSetVisible);
    
    NSAssert(newValue >= 0, @"Network Activity Indicator was asked to hide more often than shown");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(newValue > 0)];
}

- (void)loadData {
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
                self.channels[[group objectForKey:OBJECT_KEY_NAME]] = [NSArray array];
                [self loadChannelsInGroup:group];
            }
        }
    }];
}

- (void)loadSubscribedChannels {
    self.channels[SUBSCRIBED_CHANNELS] = [NSArray array];
    [self.groupNames addObject:SUBSCRIBED_CHANNELS];
    
    [self setNetworkActivityIndicatorVisible:YES];
    [self setNetworkActivityIndicatorVisible:NO];
    
    [self.tableView reloadData];
    
}

- (void)loadChannelsInGroup:(PFObject *)group {
    [self setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *channelQuery = [PFQuery queryWithClassName:OBJECT_TYPE_CHANNEL];
    [channelQuery whereKey:OBJECT_KEY_GROUP equalTo:group];
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
    
    NSArray *channels = self.channels[self.groupNames[indexPath.section]];
    PFObject *channel = channels[indexPath.row];
    cell.textLabel.text = [channel objectForKey:OBJECT_KEY_NAME];
    
    return cell;
}

@end
