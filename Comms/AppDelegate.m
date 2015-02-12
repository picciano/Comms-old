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

@interface AppDelegate ()

@end

static const DDLogLevel ddLogLevel = DDLogLevelInfo;

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeLumberjackWithOptions:launchOptions];
    [self initializeParseWithOptions:launchOptions];
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
}

- (void)initializeUserInterfaceWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [StyleKit commsTan];
    
    UIViewController *viewController = [[ViewController alloc] initWithNibName:@"MainView" bundle:nil];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.window.rootViewController = navigationController;
    
    [self.window makeKeyAndVisible];
}

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
    NSString *message = userInfo[@"aps"][@"alert"];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Remote Notification"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Okay"
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil];
    [alert addAction:defaultAction];
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
