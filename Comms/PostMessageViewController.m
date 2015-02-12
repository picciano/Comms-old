//
//  PostMessageViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "PostMessageViewController.h"

@interface PostMessageViewController ()

@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *messageCharacterCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *postMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation PostMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Post Message";
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.messageTextView becomeFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > MAXIMUM_MESSAGE_LENGTH) {
        textView.text = [textView.text substringToIndex:MAXIMUM_MESSAGE_LENGTH];
    }
    [self updateDisplay];
}

- (void)updateDisplay {
    self.messageCharacterCountLabel.text = [NSString stringWithFormat:@"%lu / %i", (unsigned long)self.messageTextView.text.length, MAXIMUM_MESSAGE_LENGTH];
    
    self.messageTextView.editable = YES;
    self.postMessageButton.enabled = (self.messageTextView.text.length > 0);
    self.cancelButton.enabled = YES;
}

- (IBAction)postMessage:(id)sender {
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    
    self.messageTextView.editable = NO;
    self.postMessageButton.enabled = NO;
    self.cancelButton.enabled = NO;
    
    PFObject *message = [PFObject objectWithClassName:OBJECT_TYPE_MESSAGE];
    [message setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
    [message setObject:self.channel forKey:OBJECT_KEY_CHANNEL];
    [message setObject:self.messageTextView.text forKey:OBJECT_KEY_TEXT];
    
    [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Posting Message"
                                                                           message:@"Please try again later."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self updateDisplay];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_POSTED_NOTIFICATION object:self];
            [self dismiss];
        }
    }];
}

- (IBAction)cancel:(id)sender {
    if ((self.messageTextView.text.length > 0)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                       message:@"Are you sure that you want to discard the unposted message?."
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"No, Stay Here"
                                                                style:UIAlertActionStyleDefault
                                                              handler:nil];
        [alert addAction:defaultAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Discard Message"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
                                                                 [self dismiss];
                                                             }];
        [alert addAction:cancelAction];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self dismiss];
    }
}

- (void)dismiss {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
