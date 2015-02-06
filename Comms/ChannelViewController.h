//
//  ChannelViewController.h
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import "ChannelInfoPanel.h"

@interface ChannelViewController : UIViewController <ChannelInfoPanelDelegate>

@property (strong, nonatomic) PFObject *channel;

@end
