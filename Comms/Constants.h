//
//  Constants.h
//  Comms
//
//  Created by Anthony Picciano on 2/5/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "AppInfoManager.h"
#import <Parse/Parse.h>
#import "CocoaLumberjack.h"

#ifndef Comms_Constants_h
#define Comms_Constants_h


#define PARSE_APPLICATION_ID        @"jtIeP2JlQH0dUvxA2rdt5apHBkiyOKlV6eZQFRDp"
#define PARSE_CLIENT_KEY            @"xoDvMRxkCfqpcguTDiywONIgHjolunDL1gVvzZNJ"

#define EMPTY_STRING                @""

#define OBJECT_TYPE_CHANNEL         @"Channel"
#define OBJECT_TYPE_GROUP           @"Group"
#define OBJECT_TYPE_MESSAGE         @"Message"
#define OBJECT_TYPE_SUBSCRIPTION    @"Subscription"

#define OBJECT_KEY_USERNAME         @"username"
#define OBJECT_KEY_PASSWORD         @"password"
#define OBJECT_KEY_CREATED_AT       @"createdAt"
#define OBJECT_KEY_UPDATED_AT       @"updatedAt"
#define OBJECT_KEY_USER             @"user"
#define OBJECT_KEY_GROUP            @"group"
#define OBJECT_KEY_NAME             @"name"
#define OBJECT_KEY_DISABLED         @"disabled"
#define OBJECT_KEY_ORDER            @"order"
#define OBJECT_KEY_CHANNEL          @"channel"
#define OBJECT_KEY_RECIPIENT        @"recipient"
#define OBJECT_KEY_TEXT             @"text"

#define CURRENT_USER_CHANGE_NOTIFICATION    @"currentUserChange"


#endif
