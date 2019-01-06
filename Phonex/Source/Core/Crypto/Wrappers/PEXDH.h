//
// Created by Dusan Klinec on 20.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXDH : NSObject

- (id) initWith: (DH *) aDh;
- (BOOL) isAllocated;
- (void) freeBuffer;
- (DH*) getRaw;
- (DH *) setRaw: (DH *) aDh;
@end