//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXInTextData.h"


@interface PEXInTextDataPhoneNumber : PEXInTextData
@property (nonatomic) NSString * phoneNumber;

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber;
+ (instancetype)numberWithPhoneNumber:(NSString *)phoneNumber;
- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber range: (NSRange) range;
+ (instancetype)numberWithPhoneNumber:(NSString *)phoneNumber range: (NSRange) range;

@end