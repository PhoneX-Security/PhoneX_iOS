//
// Created by Matej Oravec on 18/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiUtils.h"
#import "PEXGuiTextFIeld.h"
#import "PEXStringUtils.h"


@implementation PEXGuiUtils {

}

+ (void) sanitizeTextFieldInput: (UITextField * const) tf
{
    tf.text = [PEXStringUtils trimWhiteSpaces:tf.text];
}

+ (void) sanitizeTextFieldInputLowerCase: (UITextField * const) tf
{
    tf.text = [PEXStringUtils trimWhiteSpaces:tf.text].lowercaseString;
}

+ (CGFloat)pointsToPixels: (const CGFloat)points
{
    const CGFloat screenScale = [[UIScreen mainScreen] scale];
    return points * screenScale;
}

+ (CGFloat)pixelsToPoints: (const CGFloat)pixels
{
    const CGFloat screenScale = [[UIScreen mainScreen] scale];
    return pixels / screenScale;
}

+ (NSString *)rectToLog:(const CGRect)rect {
    return [NSString stringWithFormat:@"rect[%.1f, %.1f, %.1f, %.1f]",
                    rect.origin.x, rect.origin.y, rect.size.width, rect.size.height];
}


@end