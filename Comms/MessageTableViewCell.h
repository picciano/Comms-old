//
//  MessageTableViewCell.h
//  Comms
//
//  Created by Anthony Picciano on 2/9/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Message;

@interface MessageTableViewCell : UITableViewCell

@property (strong, nonatomic) Message *message;

@end
