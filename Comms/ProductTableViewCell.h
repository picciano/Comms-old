//
//  ProductTableViewCell.h
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ProductTableViewCell : UITableViewCell

@property (strong, nonatomic) SKProduct *product;

@end
