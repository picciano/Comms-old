//
//  InfoViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/16/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "InfoViewController.h"
#import "Constants.h"

#ifndef PRO
#import "CommsIAPHelper.h"
#endif

@interface InfoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *suggestPublicChannelButton;
@property (weak, nonatomic) IBOutlet UIButton *enterCodeButton;
@property (weak, nonatomic) IBOutlet UITextField *redemptionCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelNameTextField;

@end

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Info";
    
    self.view.backgroundColor = [StyleKit commsDeepGreen];
    
    [self updateDisplay];
}

- (IBAction)editingChanged:(id)sender {
    [self updateDisplay];
}

- (void)hideKeyboard {
    [self.redemptionCodeTextField resignFirstResponder];
    [self.channelNameTextField resignFirstResponder];
}

- (void)clearTextFields {
    self.redemptionCodeTextField.text = EMPTY_STRING;
    self.channelNameTextField.text = EMPTY_STRING;
}

- (void)updateDisplay {
    self.suggestPublicChannelButton.enabled = self.channelNameTextField.text.length > 3;
    self.enterCodeButton.enabled = self.redemptionCodeTextField.text.length == 8;
    
#ifdef PRO
    self.redemptionCodeTextField.hidden = YES;
    self.enterCodeButton.hidden = YES;
#endif
}

- (IBAction)readTheFAQ:(id)sender {
    NSString *url = [[PFConfig currentConfig] objectForKey:CONFIG_FAQ_URL];
    if (!url) {
        DDLogWarn(@"Parse config not loaded. Using hard-coded F.A.Q. URL.");
        url = FALLBACK_FAQ_URL;
    }
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

- (IBAction)suggestPublicChannel:(id)sender {
    [self hideKeyboard];
    
    PFObject *suggestion = [PFObject objectWithClassName:OBJECT_TYPE_SUGGESTION];
    if ([PFUser currentUser]) {
        [suggestion setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
    }
    [suggestion setObject:self.channelNameTextField.text forKey:OBJECT_KEY_TEXT];
    [suggestion saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Suggestion Noted"
                                                                       message:@"Thank you for the suggestion. We will consider adding that channel."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {
                                                                  [self clearTextFields];
                                                              }];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

#ifndef PRO
- (IBAction)enterCode:(id)sender {
    [self hideKeyboard];
    self.redemptionCodeTextField.text = [self.redemptionCodeTextField.text uppercaseString];
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_REDEMPTION_CODE];
    [query whereKey:OBJECT_KEY_CODE equalTo:self.redemptionCodeTextField.text];
    [query whereKey:OBJECT_KEY_REMAINING_USES greaterThan:@0];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *redemptionCode, NSError *error) {
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Code"
                                                                           message:@"The code you entered is no longer valid. Sorry."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self clearTextFields];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [redemptionCode incrementKey:OBJECT_KEY_REMAINING_USES byAmount:@-1];
            [redemptionCode saveEventually];
            
            int days = [[redemptionCode objectForKey:OBJECT_KEY_NUMBER_OF_DAYS] intValue];
            [[CommsIAPHelper sharedInstance] extendSubscriptionByDays:days];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Code Accepted"
                                                                           message:@"Your Pro subscription has been extended."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self clearTextFields];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}
#endif

@end
