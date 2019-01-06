//
// Created by Dusan Klinec on 01.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPushAckMsg.h"
#import "PEXPushAckPart.h"
#import "PEXUtils.h"


@implementation PEXPushAckMsg {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.acks = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)addPart:(PEXPushAckPart *)part {
    [self.acks addObject:part];
}

- (void)clear {
    [self.acks removeAllObjects];
}

- (NSMutableDictionary *)getSerializationBase {
    NSMutableArray * parts = [[NSMutableArray alloc] initWithCapacity:[self.acks count]];
    for(PEXPushAckPart * part in self.acks){
        NSMutableDictionary * partJson = [part getSerializationBase];
        if (partJson == nil){
            continue;
        }

        [parts addObject:partJson];
    }
    
    NSMutableDictionary * ret = [NSMutableDictionary dictionaryWithDictionary:
            @{
                    @"acks" : parts,
                    @"timestamp" : @(self.tstamp)
            }];

    return ret;
}

// ---------------------------------------------
#pragma mark - Generated
// ---------------------------------------------

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.acks = [coder decodeObjectForKey:@"self.acks"];
        self.tstamp = [coder decodeIntForKey:@"self.tstamp"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.acks forKey:@"self.acks"];
    [coder encodeInt:self.tstamp forKey:@"self.tstamp"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPushAckMsg *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.acks = self.acks;
        copy.tstamp = self.tstamp;
    }

    return copy;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.acks=%@", self.acks];
    [description appendFormat:@", self.tstamp=%li", self.tstamp];
    [description appendString:@">"];
    return description;
}


@end