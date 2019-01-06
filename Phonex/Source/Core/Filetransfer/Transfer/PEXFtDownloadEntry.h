//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXFtDownloadFileParams;


@interface PEXFtDownloadEntry : NSObject <NSCoding, NSCopying>
@property(nonatomic) PEXFtDownloadFileParams * params;
@property(nonatomic) BOOL storeResult;
@property(nonatomic) BOOL deleteOnly;
@property(nonatomic) BOOL processingStarted;
@property(nonatomic) volatile BOOL cancelled;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToEntry:(PEXFtDownloadEntry *)entry;
- (NSUInteger)hash;
- (NSString *)description;
@end