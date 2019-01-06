//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbCursor;
@class PEXDbContentValues;

extern NSString *PEX_DBAP_TABLE_NAME;
extern NSString *PEX_DBAP_FIELD_ID;
extern NSString *PEX_DBAP_FIELD_PERM_ID;
extern NSString *PEX_DBAP_FIELD_LIC_ID;
extern NSString *PEX_DBAP_FIELD_NAME;
extern NSString *PEX_DBAP_FIELD_LOCAL_VIEW;
extern NSString *PEX_DBAP_FIELD_SPENT;
extern NSString *PEX_DBAP_FIELD_AMOUNT;
extern NSString *PEX_DBAP_FIELD_AREF;
extern NSString *PEX_DBAP_FIELD_DATE_CREATED;
extern NSString *PEX_DBAP_FIELD_DATE_MODIFIED;
extern NSString *PEX_DBAP_FIELD_ACTION_ID_FIRST;
extern NSString *PEX_DBAP_FIELD_ACTION_CTR_FIRST;
extern NSString *PEX_DBAP_FIELD_ACTION_ID_LAST;
extern NSString *PEX_DBAP_FIELD_ACTION_CTR_LAST;
extern NSString *PEX_DBAP_FIELD_AGGREGATION_COUNT;
extern NSString *PEX_DBAP_FIELD_SUBSCRIPTION;
extern NSString *PEX_DBAP_FIELD_VALID_FROM;
extern NSString *PEX_DBAP_FIELD_VALID_TO;

@interface PEXDbAccountingPermission : PEXDbModelBase
@property (nonatomic) NSNumber * id;
@property (nonatomic) NSNumber * permId;
@property (nonatomic) NSNumber * licId;
@property (nonatomic) NSString * name;

@property (nonatomic) NSNumber * localView; // If 1 this is a local view of the counter. Otherwise it is a server view.

@property (nonatomic) NSNumber * spent;      // Currently spent value from this permission.
@property (nonatomic) NSNumber * value;     // Non-changing value of particular permission, from server.
@property (nonatomic) NSString * aref;       // Not used for now.

@property (nonatomic) NSDate * dateCreated;  // Time it was seen for the first time.
@property (nonatomic) NSDate * dateModified; // Time of the last modification.

@property (nonatomic) NSNumber * actionIdFirst;   // Accounting Log Action ID associated with this permission, first one.
@property (nonatomic) NSNumber * actionCtrFirst;  // Accounting Log Counter ID associated with this permission, first one.
@property (nonatomic) NSNumber * actionIdLast;    // Accounting Log Action ID associated with this permission, last one.
@property (nonatomic) NSNumber * actionCtrLast;   // Accounting Log Counter ID associated with this permission, last one.
@property (nonatomic) NSNumber * aggregationCount; // Number of records accounted to this permission spent record.

// Fields defined in the policy.
@property (nonatomic) NSNumber * subscription;  // If 1 the record is subscription, has from-to validity.
@property (nonatomic) NSDate * validFrom;       // Permission validity from.
@property (nonatomic) NSDate * validTo;         // Permission validity to.

+(NSArray *) getFullProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
+ (NSString *)getCreateTable;
- (void)createFromCursor:(PEXDbCursor *)c;
- (PEXDbContentValues *)getDbContentValues;
- (BOOL) isDefaultPermission;

+ (instancetype)accountingPermissionWithCursor:(PEXDbCursor *)cursor;
- (instancetype)initWithCursor:(PEXDbCursor *)cursor;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToPermission:(PEXDbAccountingPermission *)permission;
- (NSUInteger)hash;

- (NSString *)description;
@end