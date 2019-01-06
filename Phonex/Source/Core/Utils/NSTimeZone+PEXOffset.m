//
// Created by Dusan Klinec on 18.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "NSTimeZone+PEXOffset.h"

static const unsigned short int HourInSeconds = 3600;
static const unsigned short int MinuteInSeconds = 60;

@implementation NSTimeZone (PEXOffset)

+ (id)timeZoneWithStringOffset:(NSString*)offset
{
    NSString * hours = [offset substringWithRange:NSMakeRange(1, 2)];
    NSString * mins  = [offset substringWithRange:NSMakeRange(3, 2)];

    NSTimeInterval seconds = ([hours integerValue] * HourInSeconds) + ([mins integerValue] * MinuteInSeconds);
    if ([offset characterAtIndex:0] == '-') {
        seconds = seconds * -1;
    }

    return [self timeZoneForSecondsFromGMT:(NSInteger) seconds];
}

- (NSString*)offsetString
{
    BOOL negative = NO;
    NSInteger hours, mins; //!< Shouldn't ever be > 60

    NSTimeInterval seconds = [self secondsFromGMT];
    if (seconds < 0) {
        negative = YES;
        seconds = seconds * -1;
    }

    hours = (NSInteger)seconds / HourInSeconds;
    mins  = ((NSInteger)seconds % HourInSeconds) / MinuteInSeconds;

    return [NSString stringWithFormat:@"%c%02ld%02ld", negative ? '-' : '+', (long)hours, (long)mins];
}


@end