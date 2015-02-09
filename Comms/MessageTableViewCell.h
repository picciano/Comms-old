//
//  MessageTableViewCell.h
//  Comms
//
//  Created by Anthony Picciano on 2/9/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface MessageTableViewCell : UITableViewCell

@property (strong, nonatomic) PFObject *message;

@end
