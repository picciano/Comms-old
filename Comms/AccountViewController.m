//
//  AccountViewController.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "AccountViewController.h"
#import "UIControl+NextControl.h"
#import "PFObject+DateFormat.h"
#import "SecurityService.h"
#import "PFUser+UniqueIdentifier.h"
#import "Constants.h"

#define ENCRYPTION_TEST_STRING @"Hello, world!"

@interface AccountViewController ()

@property (weak, nonatomic) IBOutlet UIView *signedOutView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *signedOutViewheightConstraint;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

@property (weak, nonatomic) IBOutlet UIView *signedInView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *signedInViewheightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet UIButton *logOutButton;
@property (weak, nonatomic) IBOutlet UIButton *burnAccountButton;

@property (weak, nonatomic) IBOutlet UITextView *publicKeyBitsTextView;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

static CGFloat originalSignedOutViewheight;
static CGFloat originalSignedInViewheight;

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

@implementation AccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Account";
    
    self.view.backgroundColor = [StyleKit commsDeepGreen];
    
    originalSignedOutViewheight = self.signedOutViewheightConstraint.constant;
    originalSignedInViewheight = self.signedInViewheightConstraint.constant;
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateDisplay:NO];
}

- (IBAction)editingChanged:(id)sender {
    self.createAccountButton.enabled = self.logInButton.enabled = (self.usernameField.text.length > 0 && self.passwordField.text.length > 0);
}

- (void)clearLoginFields {
    self.usernameField.text = EMPTY_STRING;
    self.passwordField.text = EMPTY_STRING;
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self setFormFieldsEnabled:YES];
}

- (void)setFormFieldsEnabled:(BOOL)enabled {
    self.usernameField.enabled = enabled;
    self.passwordField.enabled = enabled;
    self.createAccountButton.enabled = enabled;
    self.logInButton.enabled = enabled;
}

- (void)updateDisplay:(BOOL)animated {
    BOOL signedIn = ([PFUser currentUser] != nil);
    NSTimeInterval duration = animated?0.25:0;
    
    if (signedIn) {
        self.usernameLabel.text = [[PFUser currentUser] objectForKey:OBJECT_KEY_USERNAME];
        NSString *createdAtString =[[PFUser currentUser] createdAtWithDateFormat:NSDateFormatterMediumStyle timeFormat:NSDateFormatterShortStyle];
        self.createdAtLabel.text = [NSString stringWithFormat:@"Account created %@", createdAtString];
    } else {
        [self.usernameField becomeFirstResponder];
    }
    
    self.publicKeyBitsTextView.text = EMPTY_STRING;
    
    [self editingChanged:nil];
    
    [UIView animateWithDuration:duration animations:^{
        self.signedOutViewheightConstraint.constant = (signedIn)?0:originalSignedOutViewheight;
        self.signedInViewheightConstraint.constant = (signedIn)?originalSignedInViewheight:0;
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField transferFirstResponderToNextControl];
    return NO;
}

- (IBAction)logIn:(id)sender {
    [self setFormFieldsEnabled:NO];
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
    
    [PFUser logInWithUsernameInBackground:self.usernameField.text password:self.passwordField.text block:^(PFUser *user, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        
        if (error) {
            DDLogError(@"Error during login: %@", error);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Logging In"
                                                                           message:@"Check your username and password, or maybe try creating an account instead."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self setFormFieldsEnabled:YES];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            if (![[SecurityService sharedSecurityService] publicKeyExists]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Important Notice"
                                                                               message:@"When you log into the same user account on multiple devices, only the device that logs in most recently will be able to decrypt encrypted message sent to that user. This is done to protect the private encryption key."
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:nil];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
            
            [self updatePublicKey];
            [self initializePushNotifications];
            [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_USER_CHANGE_NOTIFICATION object:self];
            [self clearLoginFields];
            [self updateDisplay:YES];
        }
    }];
}

- (IBAction)createAccount:(id)sender {
    PFUser *user = [PFUser user];
    user.username = self.usernameField.text;
    user.password = self.passwordField.text;
    
    [self setFormFieldsEnabled:NO];
    
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
    
    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        
        if (error) {
            DDLogError(@"Error during signup: %@", error);
            long code = [[error.userInfo valueForKey:@"code"] longValue];
            NSString *message = @"Sorry, could not complete sign up. Try again later.";
            if (code == 202) {
                message = @"Sorry, that username has been taken. Pick another username or login instead.";
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Signing Up"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction *action) {
                                                                      [self setFormFieldsEnabled:YES];
                                                                  }];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [self updatePublicKey];
            [self initializePushNotifications];
            [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_USER_CHANGE_NOTIFICATION object:self];
            [self clearLoginFields];
            [self updateDisplay:YES];
        }
    }];
}

- (void)updatePublicKey {
    PFUser *currentUser = [PFUser currentUser];
    NSData *publicKeyBits = [[SecurityService sharedSecurityService] getPublicKeyBits];
    [currentUser setObject:publicKeyBits forKey:OBJECT_KEY_PUBLIC_KEY];
    [currentUser saveEventually];
}

- (IBAction)logOut:(id)sender {
    [PFUser logOut];
    [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_USER_CHANGE_NOTIFICATION object:self];
    [self updateDisplay:YES];
}

- (IBAction)burnAccount:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation"
                                                                   message:@"Burning your account will permanently delete it along with any encrypted messages sent to it. This action is not reversible."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    UIAlertAction *burnAction = [UIAlertAction actionWithTitle:@"Burn Account"
                                                            style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *action) {
                                                           [self burnAccount];
                                                       }];
    [alert addAction:burnAction];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)showPublicKey:(id)sender {
    NSData *bits = [[SecurityService sharedSecurityService] getPublicKeyBits];
    self.publicKeyBitsTextView.text = [NSString stringWithFormat:@"Public Key Bits: %@", bits];
    [self testEncryption:sender];
}

- (IBAction)testEncryption:(id)sender {
    NSData *publicKeyBits = [[SecurityService sharedSecurityService] getPublicKeyBits];
    
    NSString *uid = [PFUser currentUser].uniqueIdentifier;
    
    NSData *ciphertext = [[SecurityService sharedSecurityService] encrypt:ENCRYPTION_TEST_STRING usingPublicKeyBits:publicKeyBits for:uid];
    NSString *plaintext = [[SecurityService sharedSecurityService] decrypt:ciphertext];
    
    if (plaintext == nil) {
        DDLogDebug(@"Retrying decryption...");
        plaintext = [[SecurityService sharedSecurityService] decrypt:ciphertext];
    }
    
    DDLogDebug(@"Decoded text: %@", plaintext);
    
    NSString *message = ([ENCRYPTION_TEST_STRING isEqualToString:plaintext])?@"Encryption is working correctly.":@"Encryption is not working correctly. Try logging out and back in.";
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Encryption Status"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)burnAccount {
    [AppInfoManager setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
    
    [[PFUser currentUser] deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [AppInfoManager setNetworkActivityIndicatorVisible:NO];
        [self.activityIndicator stopAnimating];
        
        if (error) {
            DDLogError(@"Error during account burn: %@", error);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Burning Account"
                                                                           message:@"Sorry, could not burn account. Try again later."
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        } else {
            [[SecurityService sharedSecurityService] deleteKeyPair];
            [PFUser logOut];
            [[NSNotificationCenter defaultCenter] postNotificationName:CURRENT_USER_CHANGE_NOTIFICATION object:self];
            [self updateDisplay:YES];
        }
    }];
}

- (void)initializePushNotifications {
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    UIApplication *application = [UIApplication sharedApplication];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

@end
