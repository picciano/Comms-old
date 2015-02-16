//
//  IAPHelper.m
//  In App Rage
//
//  Created by Ray Wenderlich on 9/5/12.
//  Copyright (c) 2012 Razeware LLC. All rights reserved.
//

#import "IAPHelper.h"
#import <StoreKit/StoreKit.h>
#import "Constants.h"

@interface IAPHelper () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@end

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

@implementation IAPHelper {
    SKProductsRequest * _productsRequest;
    RequestProductsCompletionHandler _completionHandler;
    
    NSSet * _productIdentifiers;
    NSMutableSet * _purchasedProductIdentifiers;
}

- (id)initWithProductIdentifiers:(NSSet *)productIdentifiers {
    
    if ((self = [super init])) {
        
        // Store product identifiers
        _productIdentifiers = productIdentifiers;
        
        // Check for previously purchased products
        _purchasedProductIdentifiers = [NSMutableSet set];
        for (NSString * productIdentifier in _productIdentifiers) {
            BOOL productPurchased = [[NSUserDefaults standardUserDefaults] boolForKey:productIdentifier];
            if (productPurchased) {
                [_purchasedProductIdentifiers addObject:productIdentifier];
                DDLogDebug(@"Previously purchased: %@", productIdentifier);
            } else {
                DDLogDebug(@"Not purchased: %@", productIdentifier);
            }
        }
        
        // Add self as transaction observer
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        
    }
    return self;
    
}

- (void)requestProductsWithCompletionHandler:(RequestProductsCompletionHandler)completionHandler {
    
    
    _completionHandler = [completionHandler copy];
    
    _productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:_productIdentifiers];
    _productsRequest.delegate = self;
    [_productsRequest start];
    
}

- (BOOL)productPurchased:(NSString *)productIdentifier {
    return [_purchasedProductIdentifiers containsObject:productIdentifier];
}

- (void)buyProduct:(SKProduct *)product {
    
    DDLogDebug(@"Buying %@...", product.productIdentifier);
    
    SKPayment * payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}

- (void)validateReceiptForTransaction:(SKPaymentTransaction *)transaction {
    [self provideContentForProductIdentifier:transaction.payment.productIdentifier];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    
    DDLogDebug(@"Loaded list of products...");
    _productsRequest = nil;
    
    NSArray * skProducts = response.products;
    for (SKProduct * skProduct in skProducts) {
        DDLogDebug(@"Found product: %@ %@ %0.2f",
              skProduct.productIdentifier,
              skProduct.localizedTitle,
              skProduct.price.floatValue);
    }
    
    _completionHandler(YES, skProducts);
    _completionHandler = nil;
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    DDLogError(@"Failed to load list of products.");
    _productsRequest = nil;
    
    _completionHandler(NO, nil);
    _completionHandler = nil;
    
}

#pragma mark SKPaymentTransactionOBserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction * transaction in transactions) {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    };
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    DDLogDebug(@"completeTransaction...");
    
    [self validateReceiptForTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    DDLogDebug(@"restoreTransaction...");
    
    [self validateReceiptForTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    DDLogError(@"failedTransaction...");
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        DDLogError(@"Transaction error: %@", transaction.error.localizedDescription);
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)restoreCompletedTransactions {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

#pragma mark - Subscriptions

- (int)daysRemainingOnSubscription {
    NSDate *expirationDate = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY];
    NSTimeInterval timeInt = [expirationDate timeIntervalSinceDate:[NSDate date]];
    int days = timeInt / 60 / 60 / 24;
    
    if (days > 0) {
        return days;
    } else {
        return 0;
    }
}

- (NSDate *)getExpirationDateForMonths:(int)months {
    NSDate *originDate = nil;
    
    if ([self daysRemainingOnSubscription] > 0) {
        originDate = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY];
    } else {
        originDate = [NSDate date];
    }
    
    NSDateComponents *dateComp = [[NSDateComponents alloc] init];
    [dateComp setMonth:months];
    [dateComp setDay:1]; //add an extra day to subscription because we love our users
    
    return [[NSCalendar currentCalendar] dateByAddingComponents:dateComp
                                                         toDate:originDate
                                                        options:0];
}

- (NSDate *)getExpirationDateForDays:(int)days {
    NSDate *originDate = nil;
    
    if ([self daysRemainingOnSubscription] > 0) {
        originDate = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY];
    } else {
        originDate = [NSDate date];
        days++; // to compensate for rounding down expiration date
    }
    
    NSDateComponents *dateComp = [[NSDateComponents alloc] init];
    [dateComp setDay:days];
    
    return [[NSCalendar currentCalendar] dateByAddingComponents:dateComp
                                                         toDate:originDate
                                                        options:0];
}

- (NSString *)getExpirationDateString {
    if ([self daysRemainingOnSubscription] > 0) {
        NSDate *today = [[NSUbiquitousKeyValueStore defaultStore] objectForKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY];
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MMM dd, yyyy"];
        return [NSString stringWithFormat:@"Pro Subscription is Active\nExpires: %@ (%i Days)",[dateFormat stringFromDate:today],[self daysRemainingOnSubscription]];
    } else {
        return @"Not Subscribed";
    }
}

- (void)purchaseSubscriptionWithMonths:(int)months {
    NSDate *expirationDate = [self getExpirationDateForMonths:months];
    
    [[NSUbiquitousKeyValueStore defaultStore] setObject:expirationDate forKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)provideContentForProductIdentifier:(NSString *)productIdentifier {
    if ([productIdentifier isEqualToString:ONE_MONTH_PRODUCT_IDENTIFIER]) {
        [self purchaseSubscriptionWithMonths:1];
    } else if ([productIdentifier isEqualToString:SIX_MONTH_PRODUCT_IDENTIFIER]) {
        [self purchaseSubscriptionWithMonths:6];
    } else if ([productIdentifier isEqualToString:ONE_YEAR_PRODUCT_IDENTIFIER]) {
        [self purchaseSubscriptionWithMonths:12];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PRODUCT_PURCHASED_NOTIFICATION object:productIdentifier userInfo:nil];
}

- (void)extendSubscriptionByDays:(int)days {
    NSDate *expirationDate = [self getExpirationDateForDays:days];
    
    [[NSUbiquitousKeyValueStore defaultStore] setObject:expirationDate forKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PRODUCT_PURCHASED_NOTIFICATION object:nil userInfo:nil];
}

@end