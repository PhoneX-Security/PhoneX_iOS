//
// Created by Matej Oravec on 27/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

#define TESTENTITY_TABLE_NAME "testEntity"
#define TESTENTITY_TFIELD_ID "id"
#define TESTENTITY_TFIELD_TEXT "text"
#define TESTENTITY_TFIELD_DOUBLE "double"
#define TESTENTITY_TFIELD_BLOB "blob"
#define TESTENTITY_TFIELD_LONG "int64"

@interface PEXDbTestEntity : PEXDbModelBase

@property (nonatomic) NSNumber * idField;
@property (nonatomic) NSNumber *fieldInt64;
@property (nonatomic) NSString * textField;
@property (nonatomic) NSNumber * doubleField;
@property (nonatomic) NSData  * blobField;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;

+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;


@end