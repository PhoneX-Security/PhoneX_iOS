//
// Created by Dusan Klinec on 27.08.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbContentProvider;


@interface PEXPairingFetchParams : NSObject <NSCoding, NSCopying>
@property (nonatomic) NSString * sip;
// ID of user in database - used to link contact list entry to account
@property (nonatomic) int64_t dbId;

- (id)copyWithZone:(NSZone *)zone;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end