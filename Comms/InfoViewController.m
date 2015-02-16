//
//  InfoViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/16/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "InfoViewController.h"
#import "Constants.h"

@interface InfoViewController ()

@property (weak, nonatomic) IBOutlet UIButton *suggestPublicChannelButton;
@property (weak, nonatomic) IBOutlet UIButton *enterCodeButton;
@property (weak, nonatomic) IBOutlet UITextField *redemptionCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *channelNameTextField;

@end

@implementation InfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Info";
    
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
                                                                       message:@"Thank you for the suggestion. We will consider add that public channel."
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

- (IBAction)enterCode:(id)sender {
    
}

@end
