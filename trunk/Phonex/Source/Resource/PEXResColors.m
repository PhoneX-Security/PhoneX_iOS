//
//  PEXResColors.m
//  Phonex
//
//  Created by Matej Oravec on 03/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXResColors.h"


static const NSDictionary * s_colors;

@implementation PEXResColors

+ (UIColor *) color:(const NSString * const) key
{
    return (UIColor *) [s_colors objectForKey:key];
}

+ (void) initColors
{
    const NSDictionary * const hexColors =
    [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                pathForResource:@"light"
                                                ofType:@"plist"]];
    
    NSMutableDictionary * const colors =
    [[NSMutableDictionary alloc] initWithCapacity: hexColors.count];
    
    for (const id key in hexColors)
    {
        [colors setObject: [self colorFromHexString:[hexColors objectForKey:key]]
                   forKey: key];
    }
    
    s_colors = colors;
}

+ (UIColor *) colorFromHexString: (const NSString * const) hexString
{
    const NSString * const colorString =
    [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    
    CGFloat alpha, red, blue, green;
    switch ([colorString length])
    {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
            
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
            
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
            
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
            
        default:
            [NSException raise:@"Invalid color value"
                        format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (CGFloat) colorComponentFrom: (const NSString * const) string
                         start: (const NSUInteger) start length: (const NSUInteger) length
{
    NSString * const substring =
    [string substringWithRange: NSMakeRange(start, length)];
    
    NSString * const fullHex = ((length == 2) ?
                                substring :
                                [NSString stringWithFormat: @"%@%@", substring, substring]);
    
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0f;
}

@end
