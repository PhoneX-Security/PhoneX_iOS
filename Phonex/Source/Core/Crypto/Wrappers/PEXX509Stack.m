//
// Created by Dusan Klinec on 22.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXX509Stack.h"
#import "PEXCryptoUtils.h"

@interface PEXX509Stack () {}
@property (nonatomic) STACK_OF(X509) * stack;

// For certs read from der data. Gets destroyed with this object.
@property (nonatomic) NSMutableArray * certs;
@end

@implementation PEXX509Stack {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.stack = NULL;
        self.certs = nil;
    }

    return self;
}

- (id)initWith:(STACK_OF(X509) *)aStr {
    self = [self init];
    self.stack = aStr;
    return self;
}

- (id)initWithPointerArray:(NSPointerArray *)pArray {
    self = [self init];
    if (pArray == nil || [pArray count] == 0){
        return self;
    }


    if ((_stack = sk_X509_new_null()) == NULL) {
        DDLogError(@"Error creating STACK_OF(X509) structure.");
    }

    // Iterate over cert chain and add each to the stack.
    NSUInteger count = [pArray count];
    for(NSUInteger i=0; i<count; i++) {
        const X509 * const cur = (X509 *) [pArray pointerAtIndex:i];
        sk_X509_push(_stack, cur);
    }

    return self;
}

- (id)initWithPEXX509Array:(NSArray *)xArray {
    self = [self init];
    if (xArray == nil || [xArray count] == 0){
        return self;
    }

    if ((_stack = sk_X509_new_null()) == NULL) {
        DDLogError(@"Error creating STACK_OF(X509) structure.");
    }

    // Iterate over cert chain and add each to the stack.
    NSUInteger count = [xArray count];
    for(PEXX509 * cCrt in xArray) {
        if (cCrt == nil || !cCrt.isAllocated){
            continue;
        }

        sk_X509_push(_stack, cCrt.getRaw);
    }

    return self;
}

- (id)initWithDERArray:(NSArray *)dArray {
    self = [self init];
    if (dArray == nil || [dArray count] == 0){
        return self;
    }

    if ((_stack = sk_X509_new_null()) == NULL) {
        DDLogError(@"Error creating STACK_OF(X509) structure.");
    }

    // Create cert chain for validation.
    // CA root certificates.
    _certs = [[NSMutableArray alloc] init];
    for(NSData * dder in dArray){
        PEXX509 * cCrt = [PEXCryptoUtils importCertificateFromDERWrap:dder];
        [_certs addObject:cCrt];
        sk_X509_push(_stack, cCrt.getRaw);
    }

    return self;
}


- (void) dealloc {
    // Deallocate certs.
    if (self.certs != nil){
        self.certs = nil;
    }

    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.stack!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    sk_X509_free(self.stack);
    self.stack=NULL;
    self.certs=nil;
}

- (STACK_OF(X509) *)getRaw {
    return self.stack;
}

- (STACK_OF(X509) *)setRaw:(STACK_OF(X509) *)aStr {
    STACK_OF(X509) * oldStr = self.stack;
    self.stack = aStr;
    return oldStr;
}

@end