//
//  CommsButton.m
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "CommsButton.h"
#import "StyleKit.h"

@implementation CommsButton

- (void)setTitle:(NSString *)title forState:(UIControlState)state {
    [super setTitle:title forState:state];
    [self setNeedsDisplay];
}

- (void)layoutSubviews {
    self.titleLabel.hidden = YES;
}

- (void)drawRect:(CGRect)rect {
    [StyleKit drawButtonWithFrame:self.bounds message:[self titleForState:self.state] isEnabled:self.enabled];
}

@end
