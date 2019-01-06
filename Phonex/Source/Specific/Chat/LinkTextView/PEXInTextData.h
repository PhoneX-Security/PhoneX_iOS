//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXInTextData : NSObject
@property(nonatomic) NSRange range;
@property(nonatomic) NSTextCheckingResult * match;

- (instancetype)initWithRange:(NSRange)range;
+ (instancetype)dataWithRange:(NSRange)range;

@end