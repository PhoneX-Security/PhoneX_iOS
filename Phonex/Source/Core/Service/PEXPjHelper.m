//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjHelper.h"

@implementation PEXToCall
- (instancetype)initWithPjsipAccountId:(NSNumber *)pjsipAccountId callee:(NSString *)callee {
    self = [super init];
    if (self) {
        self.pjsipAccountId = pjsipAccountId;
        self.callee = callee;
    }

    return self;
}

+ (instancetype)callWithPjsipAccountId:(NSNumber *)pjsipAccountId callee:(NSString *)callee {
    return [[self alloc] initWithPjsipAccountId:pjsipAccountId callee:callee];
}

@end

@implementation PEXPjHelper {

}
@end