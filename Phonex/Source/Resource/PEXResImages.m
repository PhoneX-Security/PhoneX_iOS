//
// Created by Matej Oravec on 03/10/14.
// Copyright (c) 2014 Matej Oravec. All rights reserved.
//


#import "PEXResImages.h"

@implementation PEXResImages {

}

+ (UIImage *) getImageNamed: (NSString * const) imageName
{
    return [UIImage imageWithContentsOfFile:
    [[PEXTheme getCurrentThemeBundle]
     pathForResource:[NSString stringWithFormat:@"Image/%@",imageName] ofType:@"png"]];
}

@end