//
//  PEXGuiSasHelper.m
//  Phonex
//
//  Created by Matej Oravec on 04/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSasHelper.h"

@implementation PEXGuiSasHelper


+ (NSString *) translate: (NSString * const) character
{
    NSString * result = [self dictionary][character];

    if (!result)
        result = @"Error";

    return result;
}

+ (NSDictionary *) dictionary
{
    static NSDictionary * result;

    result = @{ @"0" : @"0",
                @"1" : @"1",
                @"2" : @"2",
                @"3" : @"3",
                @"4" : @"4",
                @"5" : @"5",
                @"6" : @"6",
                @"7" : @"7",
                @"8" : @"8",
                @"9" : @"9",
                @"a" : @"Alpha",
                @"b" : @"Bravo",
                @"c" : @"Charlie",
                @"d" : @"Delta",
                @"e" : @"Echo",
                @"f" : @"Foxtrot",
                @"g" : @"Golf",
                @"h" : @"Hotel",
                @"i" : @"India",
                @"j" : @"Juliet",
                @"k" : @"Kilo",
                @"l" : @"Lima",
                @"m" : @"Mike",
                @"n" : @"November",
                @"o" : @"Oscar",
                @"p" : @"Papa",
                @"q" : @"Quebec",
                @"r" : @"Romeo",
                @"s" : @"Sierra",
                @"t" : @"Tango",
                @"u" : @"Uniform",
                @"v" : @"Victor",
                @"w" : @"Whiskey",
                @"x" : @"X-ray",
                @"y" : @"Yankee",
                @"z" : @"Zulu"};

    return result;
}

@end
