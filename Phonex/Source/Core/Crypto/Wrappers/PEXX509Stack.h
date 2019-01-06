//
// Created by Dusan Klinec on 22.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXX509Stack : NSObject
@property (nonatomic, readonly) STACK_OF(X509) * stack;

- (id) initWith: (STACK_OF(X509) *) aStack;

/**
* Pointer array containing X509 *
*/
- (id) initWithPointerArray: (NSPointerArray *) pArray;
- (id) initWithPEXX509Array: (NSArray *) xArray;
- (id) initWithDERArray: (NSArray *) dArray;

- (BOOL) isAllocated;
- (void) freeBuffer;
- (STACK_OF(X509) *) getRaw;
- (STACK_OF(X509) *) setRaw: (STACK_OF(X509) *) aStack;

@end