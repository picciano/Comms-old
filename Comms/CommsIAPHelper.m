//
//  CommsIAPHelper.m
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "CommsIAPHelper.h"
#import "Constants.h"

@implementation CommsIAPHelper

+ (CommsIAPHelper *)sharedInstance {
    static dispatch_once_t once;
    static CommsIAPHelper * sharedInstance;
    dispatch_once(&once, ^{
        NSSet * productIdentifiers = [NSSet setWithObjects:
                                      ONE_MONTH_PRODUCT_IDENTIFIER,
                                      SIX_MONTH_PRODUCT_IDENTIFIER,
                                      ONE_YEAR_PRODUCT_IDENTIFIER,
                                      nil];
        sharedInstance = [[self alloc] initWithProductIdentifiers:productIdentifiers];
    });
    return sharedInstance;
}

@end
