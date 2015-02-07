//
//  PFObject+DateFormat.h
//  Comms
//
//  Created by Anthony Picciano on 1/28/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import <Parse/Parse.h>

@interface PFObject (DateFormat)

- (NSString *)createdAtWithDateFormat:(NSDateFormatterStyle)dateStyle;
- (NSString *)createdAtWithDateFormat:(NSDateFormatterStyle)dateStyle timeFormat:(NSDateFormatterStyle)timeStyle;

@end
