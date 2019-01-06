//
// Created by Dusan Klinec on 20.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDH.h"

@interface PEXDH ()
@property (nonatomic) DH * dh;
@end

@implementation PEXDH {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.dh = NULL;
    }

    return self;
}

- (id)initWith:(DH *)aDh {
    self = [self init];
    self.dh = aDh;
    return self;
}

- (DH *)getRaw {
    return self.dh;
}

- (DH *) setRaw:(DH *)aDh {
    DH * oldDh = self.dh;
    self.dh = aDh;
    return oldDh;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.dh!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    DH_free(self.dh);
    self.dh=NULL;
}


@end