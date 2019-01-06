//
// Created by Dusan Klinec on 26.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXURIMatcher.h"

@interface PEXURIMatcher ()
@property(nonatomic) NSMutableDictionary * uriDb;
@end

@implementation PEXURIMatcher {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.uriDb = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)addURI:(const PEXDbUri *const)uri idx:(int)idx {
    NSNumber * key = @(idx);
    self.uriDb[key] = uri;
}

- (void)clear {
    [self.uriDb removeAllObjects];
}

- (int)match:(const PEXDbUri *const)uri {
    // Naive matching algorithm - try to match easy URI in database iterativelly.
    for(id key in self.uriDb){
        const PEXDbUri *const cUri = self.uriDb[key];
        if ([cUri matches:uri]){
            return [((NSNumber *)key) integerValue];
        }
    }

    return PEXURIMatcher_URI_NOT_FOUND;
}

@end