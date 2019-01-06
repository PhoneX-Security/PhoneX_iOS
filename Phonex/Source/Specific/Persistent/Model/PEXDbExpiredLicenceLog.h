//
// Created by Matej Oravec on 11/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"


extern NSString * const PEX_DBEXPIRED_TABLE;
extern NSString * const PEX_DBEXPIRED_FIELD_ID;
extern NSString * const PEX_DBEXPIRED_FIELD_TYPE;
extern NSString * const PEX_DBEXPIRED_FIELD_DATE;

extern const NSInteger PEX_DBEXPIRED_TYPE_OUTGOING_MESSAGE;

@interface PEXDbExpiredLicenceLog : PEXDbModelBase

@property (nonatomic) NSNumber * id;
@property (nonatomic) NSNumber * type;
@property (nonatomic) NSDate * date;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(const PEXDbUri *) getURI;
+(const PEXDbUri *) getURIBase;

+ (NSString *) getDefaultSortOrder;

+ (instancetype) expiredInfoFromCursor: (PEXDbCursor * const) c;

- (BOOL)isEqualToInfo:(PEXDbExpiredLicenceLog *)info;
@end