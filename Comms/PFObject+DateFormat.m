//
//  PFObject+DateFormat.m
//  Comms
//
//  Created by Anthony Picciano on 1/28/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//

#import "PFObject+DateFormat.h"

@implementation PFObject (DateFormat)

- (NSString *)createdAtWithDateFormat:(NSDateFormatterStyle)dateStyle {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = dateStyle;
    
    return [dateFormatter stringFromDate:self.createdAt];
}

- (NSString *)createdAtWithDateFormat:(NSDateFormatterStyle)dateStyle timeFormat:(NSDateFormatterStyle)timeStyle {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = dateStyle;
    dateFormatter.timeStyle = timeStyle;
    
    return [dateFormatter stringFromDate:self.createdAt];
}

@end
