//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXInTextData.h"


@interface PEXInTextDataLink : PEXInTextData
@property (nonatomic) NSURL * url;

- (instancetype)initWithUrl:(NSURL *)url;
+ (instancetype)linkWithUrl:(NSURL *)url;
- (instancetype)initWithUrl:(NSURL *)url range: (NSRange) range;
+ (instancetype)linkWithUrl:(NSURL *)url range: (NSRange) range;


@end