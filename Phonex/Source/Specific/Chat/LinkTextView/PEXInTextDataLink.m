//
// Created by Dusan Klinec on 18.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXInTextDataLink.h"


@implementation PEXInTextDataLink {

}
- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    if (self) {
        self.url = url;
    }

    return self;
}

+ (instancetype)linkWithUrl:(NSURL *)url {
    return [[self alloc] initWithUrl:url];
}

- (instancetype)initWithUrl:(NSURL *)url range: (NSRange) range{
    self = [super initWithRange:range];
    if (self) {
        self.url = url;
    }

    return self;
}

+ (instancetype)linkWithUrl:(NSURL *)url range: (NSRange) range{
    return [[self alloc] initWithUrl:url range:range];
}



@end