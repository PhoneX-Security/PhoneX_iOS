//
// Created by Dusan Klinec on 14.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPKCS7.h"


@interface PEXPKCS7 ()
@property (nonatomic) PKCS7 * p7;
@end

@implementation PEXPKCS7 {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.p7 = NULL;
    }

    return self;
}

- (id)initWith:(PKCS7 *)pkcs7 {
    self = [self init];
    self.p7 = pkcs7;
    return self;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.p7!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    PKCS7_free(self.p7);
    self.p7=NULL;
}

- (PKCS7 *)getRaw {
    return self.p7;
}

- (PKCS7 *)setRaw:(PKCS7 *)pkcs7 {
    PKCS7 * oldp7 = self.p7;
    self.p7 = pkcs7;
    return oldp7;
}

@end