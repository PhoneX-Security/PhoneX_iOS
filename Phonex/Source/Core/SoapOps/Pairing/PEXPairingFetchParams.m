//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPairingFetchParams.h"
#import "PEXDbContentProvider.h"


@implementation PEXPairingFetchParams {

}

- (id)copyWithZone:(NSZone *)zone {
    PEXPairingFetchParams *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.dbId = self.dbId;
        copy.sip = self.sip;
    }

    return copy;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.dbId = [coder decodeInt64ForKey:@"self.dbId"];
        self.sip = [coder decodeObjectForKey:@"self.sip"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.dbId forKey:@"self.dbId"];
    [coder encodeObject:self.sip forKey:@"self.sip"];
}


@end