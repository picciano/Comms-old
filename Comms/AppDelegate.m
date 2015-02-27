//
//  AppDelegate.m
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "Constants.h"

#ifndef PRO
#import "CommsIAPHelper.h"
#endif

@interface AppDelegate ()

@end

static const DDLogLevel ddLogLevel = DDLogLevelWarning;

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeLumberjackWithOptions:launchOptions];
    [self initializeParseWithOptions:launchOptions];
#ifndef PRO
    [self initializeICloudKeyValueStorageWithOptions:launchOptions];
    [self checkForExpiredSubscriptionAndHiddenChannels];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForExpiredSubscriptionAndHiddenChannels) name:CURRENT_USER_CHANGE_NOTIFICATION object:nil];
#endif
    [self initializeUserInterfaceWithOptions:launchOptions];
    
    return YES;
}

- (void)initializeLumberjackWithOptions:(NSDictionary *)launchOptions {
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDLogInfo(@"Cocoa Lumberjack Initialized.");
}

- (void)initializeParseWithOptions:(NSDictionary *)launchOptions {
    [Parse setApplicationId:PARSE_APPLICATION_ID
                  clientKey:PARSE_CLIENT_KEY];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    UIApplication *application = [UIApplication sharedApplication];
    if (application.applicationState != UIApplicationStateBackground) {
        // Track an app open here if we launch with a push, unless
        // "content_available" was used to trigger a background push (introduced
        // in iOS 7). In that case, we skip tracking here to avoid double
        // counting the app-open.
        BOOL preBackgroundPush = ![application respondsToSelector:@selector(backgroundRefreshStatus)];
        BOOL oldPushHandlerOnly = ![self respondsToSelector:@selector(application:didReceiveRemoteNotification:fetchCompletionHandler:)];
        BOOL noPushPayload = ![launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        if (preBackgroundPush || oldPushHandlerOnly || noPushPayload) {
            [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
        }
    }
    
    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
        if (error) {
            DDLogError(@"Parse config failed to load with error: %@", error.localizedDescription);
        } else {
            DDLogDebug(@"Parse config loaded successfully.");
        }
    }];
}

- (void)initializeUserInterfaceWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UIViewController *viewController = [[ViewController alloc] initWithNibName:@"MainView" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
}

#ifndef PRO
- (void)initializeICloudKeyValueStorageWithOptions:(NSDictionary *)launchOptions {
    // register to observe notifications from the store
    [[NSNotificationCenter defaultCenter]
     addObserver: self
     selector: @selector (storeDidChange:)
     name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
     object: [NSUbiquitousKeyValueStore defaultStore]];
    
    // get changes that might have happened while this
    // instance of your app wasn't running
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    DDLogDebug(@"Expiration Date: %@", [[NSUbiquitousKeyValueStore defaultStore] objectForKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY]);
}

- (void)storeDidChange:(NSNotification *)notification {
    DDLogDebug(@"storeDidChange notification: %@", notification);
    DDLogDebug(@"Expiration Date: %@", [[NSUbiquitousKeyValueStore defaultStore] objectForKey:PRO_SUBSCRIPTION_EXPIRATION_DATE_KEY]);
    [[NSNotificationCenter defaultCenter] postNotificationName:PRODUCT_PURCHASED_NOTIFICATION object:nil userInfo:nil];
}
#endif

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current Installation and save it to Parse.
    DDLogInfo(@"Storing the deviceToken in the current Installation and saving it to Parse.");
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setObject:[PFUser currentUser] forKey:OBJECT_KEY_USER];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    
    int type = [userInfo[@"type"] intValue];
    
    switch (type) {
        case PUSH_TYPE_NEW_MESSAGE:
            [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_POSTED_NOTIFICATION object:self];
            break;
            
        case PUSH_TYPE_SUBSCRIPTION:
            [[NSNotificationCenter defaultCenter] postNotificationName:SUBSCRIPTION_CHANGE_NOTIFICATION object:self];
            break;
            
        default:
            DDLogDebug(@"Unknow message type: %i", type);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Remote Notification"
                                                                           message:userInfo[@"aps"][@"alert"]
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:nil];
            [alert addAction:defaultAction];
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            break;
    }
}

#ifndef PRO
- (void)checkForExpiredSubscriptionAndHiddenChannels {
    if ([[CommsIAPHelper sharedInstance] daysRemainingOnSubscription] > 0) {
        return;
    }
    
    if ([PFUser currentUser] == nil) {
        return;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:OBJECT_TYPE_SUBSCRIPTION];
    [query whereKey:OBJECT_KEY_USER equalTo:[PFUser currentUser]];
    [query includeKey:OBJECT_KEY_CHANNEL];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            __block BOOL didRemoveHiddenSubscription = NO;
            [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                PFObject *subscription = obj;
                PFObject *channel = [subscription objectForKey:OBJECT_KEY_CHANNEL];
                BOOL hidden = [[channel objectForKey:OBJECT_KEY_HIDDEN] boolValue];
                if (hidden) {
                    [subscription deleteEventually];
                    didRemoveHiddenSubscription = YES;
                }
            }];
            if (didRemoveHiddenSubscription) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subscription Has Expired"
                                                                               message:@"Your pro subscription has expired and your access to hidden channels was removed. Please consider renewing your subscription."
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
                UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                                        style:UIAlertActionStyleDefault
                                                                      handler:^(UIAlertAction *action) {
                                                                          [[NSNotificationCenter defaultCenter] postNotificationName:SUBSCRIPTION_CHANGE_NOTIFICATION object:self];
                                                                      }];
                [alert addAction:defaultAction];
                [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        }
    }];
}
#endif

@end
