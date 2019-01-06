//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPairingUpdateParams.h"


@implementation PEXPairingUpdateParams {

}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.requestChanges = [coder decodeObjectForKey:@"self.requestChanges"];
    }

    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {

    }

    return self;
}

- (instancetype)initWithRequestChanges:(NSArray *)requestChanges {
    self = [super init];
    if (self) {
        self.requestChanges = requestChanges;
    }

    return self;
}

+ (instancetype)paramsWithRequestChanges:(NSArray *)requestChanges {
    return [[self alloc] initWithRequestChanges:requestChanges];
}

+ (PEXPairingUpdateParams *)paramsWithSingleId:(NSNumber *)serverId resolution:(hr_pairingRequestResolutionEnum)resolution {
    PEXPairingUpdateParams * obj = [[self alloc] init];

    hr_pairingRequestUpdateElement * elem = [[hr_pairingRequestUpdateElement alloc] init];
    elem.deleteRecord = [[USBoolean alloc] initWithBool:NO];
    elem.id_ = serverId;
    elem.resolution = resolution;

    obj.requestChanges = @[elem];
    return obj;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.requestChanges forKey:@"self.requestChanges"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPairingUpdateParams *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.requestChanges = self.requestChanges;
    }

    return copy;
}


@end