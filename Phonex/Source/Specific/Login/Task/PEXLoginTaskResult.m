//
// Created by Matej Oravec on 20/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXLoginTaskResult.h"


@implementation PEXLoginTaskResult {

}
- (instancetype)initWithResultDescription:(PEXLoginTaskResultDescription)resultDescription {
    self = [super init];
    if (self) {
        self.resultDescription = resultDescription;
    }

    return self;
}

- (instancetype)initWithResultDescription:(PEXLoginTaskResultDescription)resultDescription dbLoadResult:(PEXDbLoadResult)dbLoadResult {
    self = [super init];
    if (self) {
        self.resultDescription = resultDescription;
        self.dbLoadResult = dbLoadResult;
    }

    return self;
}

+ (instancetype)resultWithResultDescription:(PEXLoginTaskResultDescription)resultDescription dbLoadResult:(PEXDbLoadResult)dbLoadResult {
    return [[self alloc] initWithResultDescription:resultDescription dbLoadResult:dbLoadResult];
}


+ (instancetype)resultWithResultDescription:(PEXLoginTaskResultDescription)resultDescription {
    return [[self alloc] initWithResultDescription:resultDescription];
}

@end