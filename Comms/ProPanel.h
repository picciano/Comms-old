//
//  ProPanel.h
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ProPanelDelegate <NSObject>
@end

@interface ProPanel : UIView

@property (strong, nonatomic) UIView *contentView;
@property (assign, nonatomic) IBOutlet id<ProPanelDelegate> delegate;

@end
