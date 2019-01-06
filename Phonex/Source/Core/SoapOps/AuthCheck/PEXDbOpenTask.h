//
// Created by Dusan Klinec on 27.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXUserPrivate.h"
#import "PEXTaskContainer.h"
#import "PEXDbLoadResult.h"

@interface PEXDbOpenTask : PEXTaskContainer

/**
* Input parameter, is used for decrypting user database.
* Username and database password is used from this structure.
*/
@property (nonatomic) PEXUserPrivate * privData;

/**
* Stores result of the database open operation.
*/
@property (nonatomic) PEXDbLoadResult dbOpenResult;

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;

+ (instancetype)taskWithPrivData:(PEXUserPrivate *)privData;


@end