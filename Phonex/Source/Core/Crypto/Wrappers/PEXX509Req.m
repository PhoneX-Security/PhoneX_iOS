//
// Created by Dusan Klinec on 10.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXX509Req.h"

@interface PEXX509Req ()
@property (nonatomic) X509_REQ * cert;
@end

@implementation PEXX509Req {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.cert = NULL;
    }

    return self;
}

- (id)initWith:(X509_REQ *)aCrt {
    self = [self init];
    self.cert = aCrt;
    return self;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.cert!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    X509_REQ_free(self.cert);
    self.cert=NULL;
}

- (X509_REQ *)getRaw {
    return self.cert;
}

- (X509_REQ *)setRaw:(X509_REQ *)aCrt {
    X509_REQ * oldCert = self.cert;
    self.cert = aCrt;
    return oldCert;
}

@end