//
//  ChannelInfoPanel.h
//  Comms
//
//  Created by Anthony Picciano on 2/6/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChannelInfoPanelDelegate <NSObject>
@required
- (void)setSubscribed:(NSNumber *)subscribed;
- (void)postMessage;
@end

@interface ChannelInfoPanel : UIView

@property (strong, nonatomic) UIView *contentView;
@property (assign, nonatomic) IBOutlet id<ChannelInfoPanelDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *subscribedView;
@property (weak, nonatomic) IBOutlet UILabel *channelNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *subscriberCountLabel;
@property (weak, nonatomic) IBOutlet UISwitch *subscribedSwitch;

@end
