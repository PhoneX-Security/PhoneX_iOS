//
// Created by Matej Oravec on 20/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXLoginTaskResultDescription.h"
#import "PEXDbLoadResult.h"


@interface PEXLoginTaskResult : NSObject


@property (nonatomic, assign) PEXLoginTaskResultDescription resultDescription;
@property (nonatomic, assign) PEXDbLoadResult dbLoadResult;
@property (nonatomic, assign) NSDate * serverTime;
@property (nonatomic, assign) NSDate * expireTime;
@property (nonatomic) NSString * serverFailTitle;
@property (nonatomic) NSString * serverFailDesc;

- (instancetype)initWithResultDescription:(PEXLoginTaskResultDescription)resultDescription;
+ (instancetype)resultWithResultDescription:(PEXLoginTaskResultDescription)resultDescription;

- (instancetype)initWithResultDescription:(PEXLoginTaskResultDescription)resultDescription dbLoadResult:(PEXDbLoadResult)dbLoadResult;
+ (instancetype)resultWithResultDescription:(PEXLoginTaskResultDescription)resultDescription dbLoadResult:(PEXDbLoadResult)dbLoadResult;

@end