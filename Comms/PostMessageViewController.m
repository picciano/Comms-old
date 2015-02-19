//
//  PostMessageViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "PostMessageViewController.h"
#import "PFUser+UniqueIdentifier.h"
#import "SecurityService.h"

#define ENCRYPTED_STRING @"[ENCRYPTED]"

@interface PostMessageViewController ()

@property (weak, nonatomic) IBOutlet UITextView *messageTextView;
@property (weak, nonatomic) IBOutlet UILabel *messageCharacterCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *postMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation PostMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Post Message";
    
    self.view.backgroundColor = [StyleKit commsDeepGreen];
    self.messageTextView.backgroundColor = [StyleKit commsTan];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleDone target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = backButton;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateDisplay];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
    self.messageTextView.editable = NO;
    self.postMessageButton.enabled = NO;
    self.cancelButton.enabled = NO;
    
    if ([[self.channel objectForKey:OBJECT_KEY_HIDDEN] boolValue]) {
        [self postEncryptedMessages];
    } else {
        [AppInfoManager setNetworkActivityIndicatorVisible:YES];
        [self.activityIndicator startAnimating];
        
        PFObject *message = [PFObject objectWithClassName:OBJECT_TYPE_MESSAGE];
        [message setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
        [message setObject:self.channel forKey:OBJECT_KEY_CHANNEL];
        [message setObject:@NO forKey:OBJECT_KEY_ENCRYPTED];
        [message setObject:self.messageTextView.text forKey:OBJECT_KEY_TEXT];
        
        [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [AppInfoManager setNetworkActivityIndicatorVisible:NO];
            [self.activityIndicator stopAnimating];
            
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
}

- (void)postEncryptedMessages {
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [query whereKey:OBJECT_KEY_CHANNEL equalTo:self.channel];
    [query includeKey:OBJECT_KEY_USER];
    
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        
        if (error) {
            // handle error
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Posting Message"
                                                                           message:@"Subscribers public keys could not be loaded. Please try again later."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            for (PFObject *subscription in objects) {
                PFUser *recipient = [subscription objectForKey:OBJECT_KEY_USER];
                NSData *publicKeyBits = [recipient objectForKey:OBJECT_KEY_PUBLIC_KEY];
                NSData *data = [[SecurityService sharedSecurityService] encrypt:self.messageTextView.text
                                                             usingPublicKeyBits:publicKeyBits
                                                                            for:recipient.uniqueIdentifier];
                [self postEncryptedMessage:data recipient:recipient];
            }
            [self dismiss];
        }
    }];
}

- (void)postEncryptedMessage:(NSData *)data recipient:(PFUser *)recipient {
    PFObject *message = [PFObject objectWithClassName:OBJECT_TYPE_MESSAGE];
    [message setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
    [message setObject:self.channel forKey:OBJECT_KEY_CHANNEL];
    [message setObject:@YES forKey:OBJECT_KEY_ENCRYPTED];
    [message setObject:ENCRYPTED_STRING forKey:OBJECT_KEY_TEXT];
    [message setObject:data forKey:OBJECT_KEY_ENCRYPTED_DATA];
    [message setObject:recipient forKey:OBJECT_KEY_RECIPIENT];
    
    [message saveEventually:^(BOOL succeeded, NSError *error) {
        if (!succeeded || error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Posting Message"
                                                                           message:@"Encrypted message was not sent. Please try again later."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else if ([recipient.objectId isEqualToString:[PFUser currentUser].objectId]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_POSTED_NOTIFICATION object:self];
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
