//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "hr.h"


@interface PEXPairingUpdateParams : NSObject <NSCoding, NSCopying>
@property(nonatomic) NSArray * requestChanges;

- (instancetype)initWithRequestChanges:(NSArray *)requestChanges;
+ (instancetype)paramsWithRequestChanges:(NSArray *)requestChanges;

/**
 * Creates parameters with for change of a single request with given resolution.
 */
+ (PEXPairingUpdateParams *)paramsWithSingleId:(NSNumber *)serverId resolution: (hr_pairingRequestResolutionEnum) resolution;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end