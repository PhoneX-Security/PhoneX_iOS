//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXInTextDataPhoneNumber.h"


@implementation PEXInTextDataPhoneNumber {

}
- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber {
    self = [super init];
    if (self) {
        self.phoneNumber = phoneNumber;
    }

    return self;
}

+ (instancetype)numberWithPhoneNumber:(NSString *)phoneNumber {
    return [[self alloc] initWithPhoneNumber:phoneNumber];
}

- (instancetype)initWithPhoneNumber:(NSString *)phoneNumber range: (NSRange) range{
    self = [super initWithRange:range];
    if (self) {
        self.phoneNumber = phoneNumber;
    }

    return self;
}

+ (instancetype)numberWithPhoneNumber:(NSString *)phoneNumber range: (NSRange) range{
    return [[self alloc] initWithPhoneNumber:phoneNumber range:range];
}

@end