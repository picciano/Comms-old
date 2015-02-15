//
//  ProductTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ProductTableViewCell.h"

@implementation ProductTableViewCell

- (void)setProduct:(SKProduct *)product {
    _product = product;
    self.textLabel.text = self.product.localizedTitle;
}

@end
