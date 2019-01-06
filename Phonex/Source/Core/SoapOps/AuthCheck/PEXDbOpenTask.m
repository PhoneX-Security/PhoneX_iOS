//
// Created by Dusan Klinec on 27.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbOpenTask.h"
#import "PEXUserPrivate.h"
#import "PEXDatabase.h"

@implementation PEXDbOpenTask {

}

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData {
    self = [super init];
    if (self) {
        self.privData = privData;
    }

    return self;
}

+ (instancetype)taskWithPrivData:(PEXUserPrivate *)privData {
    return [[self alloc] initWithPrivData:privData];
}

@end