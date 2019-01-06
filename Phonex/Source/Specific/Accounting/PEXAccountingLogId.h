//
// Created by Dusan Klinec on 02.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXAccountingLogId : NSObject <NSCoding, NSCopying>
@property (nonatomic) NSNumber * id;
@property (nonatomic) NSNumber * ctr;

- (instancetype)initWithId:(NSNumber *)id ctr:(NSNumber *)ctr;
+ (instancetype)idWithId:(NSNumber *)id ctr:(NSNumber *)ctr;

+ (NSComparisonResult) compare:(PEXAccountingLogId *) a b:(PEXAccountingLogId *) b;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToId:(PEXAccountingLogId *)logId;
- (NSUInteger)hash;
- (NSString *)description;

@end