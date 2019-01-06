//
// Created by Dusan Klinec on 22.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXX509Store.h"

@interface PEXX509Store () {}
@property (nonatomic) X509_STORE * str;
@end

@implementation PEXX509Store {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.str = NULL;
    }

    return self;
}

- (id)initWith:(X509_STORE *)aStr {
    self = [self init];
    self.str = aStr;
    return self;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.str!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    X509_STORE_free(self.str);
    self.str=NULL;
}

- (X509_STORE *)getRaw {
    return self.str;
}

- (X509_STORE *)setRaw:(X509_STORE *)aStr {
    X509_STORE * oldStr = self.str;
    self.str = aStr;
    return oldStr;
}

@end