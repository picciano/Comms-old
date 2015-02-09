//
//  HeaderView.m
//  Hunch
//
//  Created by Anthony Picciano on 2/3/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "HeaderView.h"
#import "StyleKit.h"

@implementation HeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [StyleKit commsDarkTan];
    }
    return self;
}

@end
