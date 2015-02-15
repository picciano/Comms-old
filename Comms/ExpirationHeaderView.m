//
//  ExpirationHeaderView.m
//  Hunch
//
//  Created by Anthony Picciano on 2/3/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ExpirationHeaderView.h"
#import "StyleKit.h"

@implementation ExpirationHeaderView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [StyleKit commsDarkTan];
    }
    return self;
}

@end
