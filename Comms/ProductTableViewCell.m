//
//  ProductTableViewCell.m
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "ProductTableViewCell.h"
#import "CommsIAPHelper.h"
#import "Constants.h"

@interface ProductTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *productNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *subscribeButton;

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation ProductTableViewCell

- (void)setProduct:(SKProduct *)product {
    _product = product;
    self.productNameLabel.text = self.product.localizedTitle;
    self.priceLabel.text = [[ProductTableViewCell priceFormatter] stringFromNumber:self.product.price];
    self.descriptionLabel.text = self.product.localizedDescription;
    
    // Buy Button
    if ([[CommsIAPHelper sharedInstance] daysRemainingOnSubscription] > 0) {
        [self.subscribeButton setTitle:@"Renew" forState:UIControlStateNormal];
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGRect contentViewFrame = self.contentView.frame;
    contentViewFrame.size.width = self.bounds.size.width;
    self.contentView.frame = contentViewFrame;
}

+ (NSNumberFormatter *)priceFormatter {
    static dispatch_once_t once;
    static NSNumberFormatter *_priceFormatter;
    dispatch_once(&once, ^{
        _priceFormatter = [[NSNumberFormatter alloc] init];
        [_priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
        [_priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    });
    
    return _priceFormatter;
}

- (IBAction)subscribeButtonTapped:(id)sender {
    DDLogDebug(@"Buying %@...", self.product.productIdentifier);
    [[CommsIAPHelper sharedInstance] buyProduct:self.product];
}

@end
