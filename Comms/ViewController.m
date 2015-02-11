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
#import "HeaderView.h"
#import "Constants.h"

#define SUBSCRIBED_CHANNELS     @"Subscribed Channels"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet AccountPanel *accountPanel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong) NSMutableDictionary *channels;
@property (strong) NSMutableArray *groupNames;

// Used by hidden channel name dialog to enable/disable action
@property (strong, nonatomic) UIAlertAction *joinAction;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSubscribedChannels) name:CURRENT_USER_CHANGE_NOTIFICATION object:nil];
}

#pragma mark - data loading

- (void)loadData {
    [self.groupNames addObject:SUBSCRIBED_CHANNELS];
    [self loadSubscribedChannels];
    
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *groupsQuery = [PFQuery queryWithClassName:OBJECT_TYPE_GROUP];
    [groupsQuery orderByAscending:OBJECT_KEY_ORDER];
    [groupsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            DDLogError(@"Error loading data: %@", error);
        } else {
            for (PFObject *group in objects) {
                [self.groupNames addObject:[group objectForKey:OBJECT_KEY_NAME]];
                [self loadChannelsInGroup:group];
            }
        }
    }];
}

- (void)loadSubscribedChannels {
    
    if (![PFUser currentUser]) {
        [self.channels removeObjectForKey:SUBSCRIBED_CHANNELS];
        [self.tableView reloadData];
        return;
    }
    
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *subscriptionQuery = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [subscriptionQuery whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_CHANNEL];
    [query whereKey:OBJECT_KEY_OBJECT_ID matchesKey:OBJECT_KEY_CHANNEL_ID inQuery:subscriptionQuery];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        if (error) {
            DDLogError(@"Error loading data: %@", error);
        } else {
            self.channels[SUBSCRIBED_CHANNELS] = objects;
            [self.tableView reloadData];
        }
    }];
}

- (void)loadChannelsInGroup:(PFObject *)group {
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *channelQuery = [PFQuery queryWithClassName:OBJECT_TYPE_CHANNEL];
    [channelQuery whereKey:OBJECT_KEY_GROUP equalTo:group];
    [channelQuery whereKey:OBJECT_KEY_DISABLED equalTo:@NO];
    [channelQuery orderByAscending:OBJECT_KEY_NAME];
    [channelQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        
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

- (void)viewChannel:(PFObject *)channel {
    ChannelViewController *viewController = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
    viewController.channel = channel;
    [self.navigationController pushViewController:viewController animated:YES];
}

- (IBAction)navigateToAccountView:(id)sender {
    UIViewController *viewController = [[AccountViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Join or Create Hidden Channel

- (IBAction)showHiddenChannelDialog:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hidden Channel"
                                                                   message:@"Please enter the name of the hidden channel. If the channel exists, you will be subscribed. If it does not, the channel will be created."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alert addAction:cancelAction];
    self.joinAction = [UIAlertAction actionWithTitle:@"Join or Create"
                                               style:UIAlertActionStyleDefault
                                             handler:^(UIAlertAction *action) {
                                                 NSString *channelName = ((UITextField *)[alert.textFields objectAtIndex:0]).text;
                                                 [self createOrJoinHiddenChannel:channelName];
                                             }];
    self.joinAction.enabled = NO;
    [alert addAction:self.joinAction];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Channel Name";
        [textField addTarget:self action:@selector(hiddenChannelNameChanges:) forControlEvents:UIControlEventEditingChanged];
        textField.delegate = self;
    }];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)createOrJoinHiddenChannel:(NSString *)channelName {
    DDLogDebug(@"createOrJoinHiddenChannel: %@", channelName);
    
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFQuery *channelQuery = [PFQuery queryWithClassName:OBJECT_TYPE_CHANNEL];
    [channelQuery whereKey:OBJECT_KEY_NAME equalTo:channelName];
    [channelQuery getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            //create channel
            PFObject *channel = [PFObject objectWithClassName:OBJECT_TYPE_CHANNEL];
            [channel setObject:channelName forKey:OBJECT_KEY_NAME];
            [channel setObject:@NO forKey:OBJECT_KEY_DISABLED];
            
            [AppInfoManager setNetworkActivityIndicatorVisible:YES];
            
            [channel saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                [AppInfoManager setNetworkActivityIndicatorVisible:NO];
                
                if (error) {
                    // notice to user
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Creating Channel"
                                                                                   message:@"The channel could not be created. Try again later."
                                                                            preferredStyle:UIAlertControllerStyleActionSheet];
                    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:nil];
                    [alert addAction:defaultAction];
                } else {
                    // subscribe
                    [self subscribeToChannel:channel];
                }
            }];
        } else {
            //subscribe
            [self subscribeToChannel:object];
        }
    }];
}

- (void)subscribeToChannel:(PFObject *)channel {
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    PFObject *subscription = [PFObject objectWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [subscription setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
    [subscription setObject:channel forKey:OBJECT_KEY_CHANNEL];
    [subscription saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            // notice to user
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Subscribing"
                                                                           message:@"The channel could not be subscribed to. Try again later."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [alert addAction:defaultAction];
        } else {
            [AppInfoManager setNetworkActivityIndicatorVisible:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:SUBSCRIPTION_CHANGE_NOTIFICATION object:self];
            [self viewChannel:channel];
        }
    }];
}

- (IBAction)hiddenChannelNameChanges:(id)sender {
    UITextField *textField = (UITextField *)sender;
    self.joinAction.enabled = (textField.text.length > 0);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField  {
    return (textField.text.length > 0);
}

#pragma mark - tableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groupNames.count;
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    HeaderView *view = [[[NSBundle mainBundle] loadNibNamed:@"HeaderView" owner:self options:nil] firstObject];
    view.titleLabel.text = self.groupNames[section];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSArray *channels = self.channels[self.groupNames[section]];
    return (channels.count > 0)?30:0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ChannelViewController *viewController = [[ChannelViewController alloc] initWithNibName:nil bundle:nil];
    viewController.channel = [self channelAtIndexPath:indexPath];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end
