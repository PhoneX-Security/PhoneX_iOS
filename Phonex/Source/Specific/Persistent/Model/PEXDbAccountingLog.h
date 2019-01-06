//
// Created by Dusan Klinec on 01.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbCursor;
@class PEXDbContentValues;
@class PEXDbAppContentProvider;
@class PEXDbContentProvider;

extern NSString *PEX_DBAL_TABLE_NAME;
extern NSString *PEX_DBAL_FIELD_ID;
extern NSString *PEX_DBAL_FIELD_TYPE;
extern NSString *PEX_DBAL_FIELD_RKEY;
extern NSString *PEX_DBAL_FIELD_DATE_CREATED;
extern NSString *PEX_DBAL_FIELD_DATE_MODIFIED;
extern NSString *PEX_DBAL_FIELD_ACTION_ID;
extern NSString *PEX_DBAL_FIELD_ACTION_COUNTER;
extern NSString *PEX_DBAL_FIELD_AMOUNT;
extern NSString *PEX_DBAL_FIELD_AGGREGATED;
extern NSString *PEX_DBAL_FIELD_AREF;
extern NSString *PEX_DBAL_FIELD_PERM_ID;
extern NSString *PEX_DBAL_FIELD_LIC_ID;

@interface PEXDbAccountingLog : PEXDbModelBase
@property (nonatomic) NSNumber * id;
@property (nonatomic) NSString * type;              // Name of the counter / permission. Compact form.
@property (nonatomic) NSString * rkey;              // Not used. Unique text identifier.
@property (nonatomic) NSDate * dateCreated;         // Record first created date time.
@property (nonatomic) NSDate * dateModified;        // Record last modification date time.
@property (nonatomic) NSNumber * actionId;          // Milliseconds from UTC when this record was created.
@property (nonatomic) NSNumber * actionCounter;     // Monotonically increasing counter sequence.  (actionId, actionCounter) is an unique key.
@property (nonatomic) NSNumber * amount;            // Amount of units consumed from the counter / permission.
@property (nonatomic) NSNumber * aggregated;        // Number of records aggregated in this record.
@property (nonatomic) NSString * aref;              // Not used.
@property (nonatomic) NSNumber * permId;            // Optional. Permission ID to account for this spend record.
@property (nonatomic) NSNumber * licId;             // Optional. License ID to account for this spend record.

+(NSArray *) getFullProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
+ (NSString *)getCreateTable;
- (void)createFromCursor:(PEXDbCursor *)c;
- (PEXDbContentValues *)getDbContentValues;

- (instancetype)initWithCursor:(PEXDbCursor *)cursor;
+ (instancetype)accountingLogWithCursor:(PEXDbCursor *)cursor;

+ (int) deleteRecordsOlderThan: (NSNumber *) actionId actionCtr: (NSNumber *) actionCtr cr: (PEXDbContentProvider *) cr;

@end