//
// Created by Dusan Klinec on 11.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXEVPPKey.h"
#import "openssl/evp.h"

@interface PEXEVPPKey ()
@property (nonatomic) EVP_PKEY * key;
@end


@implementation PEXEVPPKey {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.key = NULL;
    }

    return self;
}

- (id) initWith: (EVP_PKEY *) aKey {
    self = [self init];
    self.key = aKey;
    return self;
}

- (EVP_PKEY *)getRaw {
    return self.key;
}

- (EVP_PKEY *) setRaw:(EVP_PKEY *)aKey {
    EVP_PKEY * old = self.key;
    self.key = aKey;
    return old;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.key!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    EVP_PKEY_free(self.key);
    self.key=NULL;
}

@end