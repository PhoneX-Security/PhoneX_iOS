//
// Created by Dusan Klinec on 27.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPKCS12.h"

@interface PEXPKCS12 ()
@property (nonatomic) PKCS12 * p12;
@end

@implementation PEXPKCS12 {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.p12 = NULL;
    }

    return self;
}

- (id)initWith:(PKCS12 *)pkcs12 {
    self = [self init];
    self.p12 = pkcs12;
    return self;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.p12!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    PKCS12_free(self.p12);
    self.p12=NULL;
}

- (PKCS12 *)getRaw {
    return self.p12;
}

- (PKCS12 *)setRaw:(PKCS12 *)pkcs12 {
    PKCS12 * oldp12 = self.p12;
    self.p12 = pkcs12;
    return oldp12;
}

@end