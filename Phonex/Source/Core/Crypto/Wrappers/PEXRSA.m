//
// Created by Dusan Klinec on 10.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXRSA.h"

@interface PEXRSA ()
@property (nonatomic) RSA * rsa;
@end

@implementation PEXRSA {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.rsa = NULL;
    }

    return self;
}

- (id)initWith:(RSA *)aRsa {
    self = [self init];
    self.rsa = aRsa;
    return self;
}

- (RSA *)getRaw {
    return self.rsa;
}

- (RSA *) setRaw:(RSA *)aRsa {
    RSA * oldRsa = self.rsa;
    self.rsa = aRsa;
    return oldRsa;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.rsa!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    RSA_free(self.rsa);
    self.rsa=NULL;
}

@end