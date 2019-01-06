//
// Created by Dusan Klinec on 02.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (PEXResCrypto)

- (NSString *)pathForDHGroupId:(int) groupID;
- (NSString *)pathForCARoots;
- (NSString *)pathForCAWebRoots;

/**
 * Expired certificates used to sign user certificates.
 * Users in the wild still may have these certificates so
 * for a short transition period in disaster recovery
 * we temporarily allow them.
 */
- (NSString *)pathForCARootsExpired;

@end