//
//  InAppPurchaseViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/15/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "InAppPurchaseViewController.h"
#import "ProductTableViewCell.h"
#import "ExpirationHeaderView.h"
#import "CommsIAPHelper.h"
#import "Constants.h"

@interface InAppPurchaseViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *products;

@end

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

static NSString *kProductReuseIdentifier = @"kProductReuseIdentifier";

@implementation InAppPurchaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pro Subscription";
    
    [self reload];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ProductTableViewCell"bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:kProductReuseIdentifier];
}

- (void)reload {
    self.products = nil;
    [self.tableView reloadData];
    [[CommsIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success, NSArray *products) {
        if (success) {
            DDLogDebug(@"Products loaded.");
            self.products = products;
            [self.tableView reloadData];
        }
    }];
}

- (void)productPurchased:(NSNotification *)notification {
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:PRODUCT_PURCHASED_NOTIFICATION object:nil];
    
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ExpirationHeaderView *view = [[[NSBundle mainBundle] loadNibNamed:@"ExpirationHeaderView" owner:self options:nil] firstObject];
    NSString *expirationDateString = [[CommsIAPHelper sharedInstance] getExpirationDateString];
    view.titleLabel.text = expirationDateString;
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 60.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 140.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProductReuseIdentifier forIndexPath:indexPath];
    cell.product = self.products[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
