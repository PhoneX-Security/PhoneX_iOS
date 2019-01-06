//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXFtUploadParams;


@interface PEXFtUploadEntry : NSObject <NSCopying, NSCoding>
@property(nonatomic) PEXFtUploadParams * params;
@property(nonatomic) BOOL processingStarted;
@property(nonatomic) volatile BOOL cancelled;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end