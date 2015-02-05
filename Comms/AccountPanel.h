//
//  AccountPanel.h
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AccountPanelDelegate <NSObject>
@required
-(void)navigateToAccountView:(id)sender;
@end

IB_DESIGNABLE
@interface AccountPanel : UIView

@property (strong, nonatomic) UIView *contentView;
@property (assign, nonatomic) IBOutlet id<AccountPanelDelegate> delegate;

@end
