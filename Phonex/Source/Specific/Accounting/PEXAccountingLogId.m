//
// Created by Dusan Klinec on 02.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAccountingLogId.h"


@implementation PEXAccountingLogId {

}
- (instancetype)initWithId:(NSNumber *)id ctr:(NSNumber *)ctr {
    self = [super init];
    if (self) {
        self.id = id;
        self.ctr = ctr;
    }

    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.ctr = [coder decodeObjectForKey:@"self.ctr"];
        self.id = [coder decodeObjectForKey:@"self.id"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.ctr forKey:@"self.ctr"];
    [coder encodeObject:self.id forKey:@"self.id"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXAccountingLogId *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.ctr = self.ctr;
        copy.id = self.id;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToId:other];
}

- (BOOL)isEqualToId:(PEXAccountingLogId *)logId {
    if (self == logId)
        return YES;
    if (logId == nil)
        return NO;
    if (self.ctr != logId.ctr && ![self.ctr isEqualToNumber:logId.ctr])
        return NO;
    if (self.id != logId.id && ![self.id isEqualToNumber:logId.id])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = [self.ctr hash];
    hash = hash * 31u + [self.id hash];
    return hash;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.ctr=%@", self.ctr];
    [description appendFormat:@", self.id=%@", self.id];
    [description appendString:@">"];
    return description;
}


+ (instancetype)idWithId:(NSNumber *)id ctr:(NSNumber *)ctr {
    return [[self alloc] initWithId:id ctr:ctr];
}

+ (NSComparisonResult)compare:(PEXAccountingLogId *)a b:(PEXAccountingLogId *)b {

    NSComparisonResult resId = [a.id compare: b.id];
    if (resId == NSOrderedSame) {

        NSComparisonResult resCtr = [a.ctr compare: b.ctr];
        if (resCtr == NSOrderedSame) {
            return NSOrderedSame;
        }

        return resCtr == NSOrderedAscending ? NSOrderedAscending : NSOrderedDescending;
    }

    return resId == NSOrderedAscending ? NSOrderedAscending : NSOrderedDescending;
}


@end