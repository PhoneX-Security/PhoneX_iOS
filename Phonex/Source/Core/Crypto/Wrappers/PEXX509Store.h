//
// Created by Dusan Klinec on 22.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXX509Store : NSObject
@property (nonatomic, readonly) X509_STORE * str;

- (id) initWith: (X509_STORE *) aStr;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (X509_STORE *) getRaw;
- (X509_STORE *) setRaw: (X509_STORE *) aStr;
@end