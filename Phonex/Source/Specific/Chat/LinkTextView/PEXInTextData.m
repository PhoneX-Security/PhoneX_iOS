//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXInTextData.h"


@implementation PEXInTextData {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        _range.length = 0;
        _range.location = 0;
    }

    return self;
}

- (instancetype)initWithRange:(NSRange)range {
    self = [self init];
    if (self) {
        self.range = range;
    }

    return self;
}

+ (instancetype)dataWithRange:(NSRange)range {
    return [[self alloc] initWithRange:range];
}


@end