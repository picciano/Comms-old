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
#import "MessageTableViewCell.h"
#import "Constants.h"

@interface ChannelViewController ()

@property (weak, nonatomic) IBOutlet ChannelInfoPanel *channelInfoPanel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, atomic) NSArray *messages;

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

static NSString *kMessageReuseIdentifier = @"kMessageReuseIdentifier";

@implementation ChannelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [self.channel objectForKey:OBJECT_KEY_NAME];
    self.channelInfoPanel.channelNameLabel.text = [self.channel objectForKey:OBJECT_KEY_NAME];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MessageTableViewCell"bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kMessageReuseIdentifier];
    
    [self loadSubscriptionStatus];
    [self loadSubscriptionCount];
    [self loadMessages];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSubscriptionCount) name:SUBSCRIPTION_CHANGE_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadMessages) name:MESSAGE_POSTED_NOTIFICATION object:nil];
}

- (void)loadSubscriptionStatus {
    
    if (![PFUser currentUser]) {
        self.channelInfoPanel.subscribedView.hidden = YES;
        return;
    }
    
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [query whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
    [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        if (!error) {
            self.channelInfoPanel.subscribedSwitch.on = YES;
        }
    }];
}

- (void)loadSubscriptionCount {
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    self.channelInfoPanel.subscriberCountLabel.text = EMPTY_STRING;
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        if (!error) {
            self.channelInfoPanel.subscriberCountLabel.text = [NSString stringWithFormat:@"%i Subscriber%@", number, (number==1)?@"":@"s"];
        }
    }];
}

- (void)loadMessages {
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_MESSAGE];
    [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
    [query orderByDescending:OBJECT_KEY_CREATED_AT];
    [query includeKey:OBJECT_KEY_USER];
    
    if ([[self.channel objectForKey:OBJECT_KEY_HIDDEN] boolValue]) {
        [query whereKey:OBJECT_KEY_RECIPIENT equalTo:[PFUser currentUser]];
    }
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        
        if (!error) {
            self.messages = objects;
            [self.tableView reloadData];
        }
    }];
}

- (void)setSubscribed:(NSNumber *)subscribed {
    BOOL on = [subscribed boolValue];
    if (on) {
        [AppInfoManager setNetworkActivityIndicatorVisible:YES];
        
        PFObject *subscription = [PFObject objectWithClassName:OBJECT_TYPE_SUBSCRIPTION];
        [subscription setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
        [subscription setObject:self.channel forKey:OBJECT_KEY_CHANNEL];
        [subscription saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [AppInfoManager setNetworkActivityIndicatorVisible:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:SUBSCRIPTION_CHANGE_NOTIFICATION object:self];
        }];
    } else {
        [AppInfoManager setNetworkActivityIndicatorVisible:YES];
        
        PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
        [query whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
        [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            [AppInfoManager setNetworkActivityIndicatorVisible:NO];
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
    PostMessageViewController *viewController = [[PostMessageViewController alloc] initWithNibName:nil bundle:nil];
    viewController.channel = self.channel;
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [MessageTableViewCell heightForMessage:self.messages[indexPath.row] frame:CGRectMake(0, 0, self.tableView.frame.size.width, INFINITY)];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageReuseIdentifier forIndexPath:indexPath];
    cell.message = self.messages[indexPath.row];
    
    return cell;
}

@end
