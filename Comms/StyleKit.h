//
//  StyleKit.h
//  Comms
//
//  Created by Anthony Picciano on 2/12/15.
//  Copyright (c) 2015 Anthony Picciano. All rights reserved.
//
//  Generated by PaintCode (www.paintcodeapp.com)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface StyleKit : NSObject

// Colors
+ (UIColor*)commsWhite;
+ (UIColor*)commsTan;
+ (UIColor*)commsLightGreen;
+ (UIColor*)commsPeach;
+ (UIColor*)commsDeepViolet;
+ (UIColor*)commsBlue;
+ (UIColor*)commsBlack;
+ (UIColor*)commsDeepGreen;
+ (UIColor*)commsDarkTan;
+ (UIColor*)commsGreen;
+ (UIColor*)commsOrange;

// Drawing Methods
+ (void)drawLogoWithFrame: (CGRect)frame isPro: (BOOL)isPro isFree: (BOOL)isFree;
+ (void)drawButtonWithLabelText: (NSString*)labelText;
+ (void)drawBigLabelWithLabelText: (NSString*)labelText;
+ (void)drawMessageBlockWithFrame: (CGRect)frame isLocked: (BOOL)isLocked senderUsername: (NSString*)senderUsername createdAt: (NSString*)createdAt message: (NSString*)message;
+ (void)drawLockIconWithFrame: (CGRect)frame lockColor: (UIColor*)lockColor keyColor: (UIColor*)keyColor isLocked: (BOOL)isLocked;

@end
