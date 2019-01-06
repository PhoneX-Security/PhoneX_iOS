//
//  PEXResDimensions.m
//  Phonex
//
//  Created by Matej Oravec on 02/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

static const NSMutableDictionary * s_values;

static CGFloat s_itemHeight;
static CGFloat s_thumbnailSize;
static CGFloat s_thumbnailDetailSize;

@implementation PEXResValues

+ (CGFloat) value:(NSString * const) key
{
    return [[s_values objectForKey:key] floatValue];
}

+ (void) initValues
{
    s_values =
    [NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                pathForResource:@"portrait"
                                                ofType:@"plist"]];

    [s_values addEntriesFromDictionary:
     [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]
                                                 pathForResource:@"independent_values"
                                                 ofType:@"plist"]]];

    [self postInit];
}

+ (void) postInit
{
    s_itemHeight = (3.0f * PEXVal(@"dim_size_medium")) + PEXVal(@"dim_size_small_medium");
    s_thumbnailSize = 1.5f * s_itemHeight;
    s_thumbnailDetailSize = 8.0f * s_itemHeight;
}

/// DICTIONARY: TODO: MOVE AWAY

+ (CGFloat) getItemHeight
{
    return s_itemHeight;
}

+ (CGFloat) getThumbnailSize
{
    return s_thumbnailSize;
}

+ (CGFloat) getThumbnailDetailSize
{
    return s_thumbnailDetailSize;
}

@end
