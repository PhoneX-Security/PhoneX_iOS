//
// Created by Matej Oravec on 18/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXGuiUtils : NSObject

+ (void) sanitizeTextFieldInput: (UITextField * const) tf;
+ (void) sanitizeTextFieldInputLowerCase: (UITextField * const) tf;

+ (CGFloat)pointsToPixels: (const CGFloat)points;
+ (CGFloat)pixelsToPoints: (const CGFloat)pixels;
+ (NSString*) rectToLog: (const CGRect) rect;
@end