//
//  ChannelTableViewCell.h
//  Comms
//
//  Created by Anthony Picciano on 2/6/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ChannelTableViewCell : UITableViewCell

@property (strong, nonatomic) PFObject *channel;

@end
