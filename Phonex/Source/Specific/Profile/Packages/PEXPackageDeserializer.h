//
// Created by Matej Oravec on 05/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPackageDeserializer : NSObject

+ (NSArray *) getPackagesFromJson: (NSDictionary * const) json;

@end