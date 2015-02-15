//
//  InAppPurchaseViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "InAppPurchaseViewController.h"
#import "CommsIAPHelper.h"
#import "ProductTableViewCell.h"
#import "Constants.h"

@interface InAppPurchaseViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *products;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSNumberFormatter *priceFormatter;

@end

static const DDLogLevel ddLogLevel = DDLogLevelDebug;
static NSString *kProductReuseIdentifier = @"kProductReuseIdentifier";

@implementation InAppPurchaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pro Subscription";
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(reload) forControlEvents:UIControlEventValueChanged];
    [self reload];
    [self.refreshControl beginRefreshing];
    
    self.priceFormatter = [[NSNumberFormatter alloc] init];
    [self.priceFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [self.priceFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ProductTableViewCell"bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kProductReuseIdentifier];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Restore" style:UIBarButtonItemStylePlain target:self action:@selector(restoreTapped:)];
}

- (void)restoreTapped:(id)sender {
    [[CommsIAPHelper sharedInstance] restoreCompletedTransactions];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    [self.tableView reloadData];
}

- (void)reload {
    self.products = nil;
    [self.tableView reloadData];
    [[CommsIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            self.products = products;
            [self.tableView reloadData];
        }
        [self.refreshControl endRefreshing];
    }];
}

//- (void)productPurchased:(NSNotification *)notification {
//    
//    NSString * productIdentifier = notification.object;
//    [_products enumerateObjectsUsingBlock:^(SKProduct * product, NSUInteger idx, BOOL *stop) {
//        if ([product.productIdentifier isEqualToString:productIdentifier]) {
//            if ([product.productIdentifier hasSuffix:@"monthlyrageface"]) {
//                [self reload];
//                [self.refreshControl beginRefreshing];
//            } else {
//                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
//            }
//            *stop = YES;
//        }
//    }];
//}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:IAPHelperProductPurchasedNotification object:nil];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableView methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.products.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProductReuseIdentifier forIndexPath:indexPath];
    cell.product = self.products[indexPath.row];
    return cell;
}

@end
