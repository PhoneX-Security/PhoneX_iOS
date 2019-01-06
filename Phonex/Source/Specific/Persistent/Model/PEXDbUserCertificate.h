//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbContentValues.h"
#import "PEXX509.h"
#import "PEXDbCursor.h"
#import "PEXDbModelBase.h"

@class PEXDbContentProvider;

// Naming macro for callers.
#define UserCertificate(X)  PEX_UCRT_##X

FOUNDATION_EXPORT NSString * const PEX_UCRT_TABLE;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_ID;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_OWNER;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_CERTIFICATE_STATUS;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_CERTIFICATE;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_CERTIFICATE_HASH;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_DATE_LAST_QUERY;
FOUNDATION_EXPORT NSString * const PEX_UCRT_FIELD_DATE_CREATED;
FOUNDATION_EXPORT NSString * const PEX_UCRT_DATE_FORMAT;
FOUNDATION_EXPORT const int64_t PEX_UCRT_INVALID_ID;

FOUNDATION_EXPORT NSInteger const CERTIFICATE_STATUS_OK;
FOUNDATION_EXPORT NSInteger const CERTIFICATE_STATUS_INVALID;
FOUNDATION_EXPORT NSInteger const CERTIFICATE_STATUS_REVOKED;
FOUNDATION_EXPORT NSInteger const CERTIFICATE_STATUS_FORBIDDEN;
FOUNDATION_EXPORT NSInteger const CERTIFICATE_STATUS_MISSING;
FOUNDATION_EXPORT NSInteger const CERTIFICATE_STATUS_NOUSER;

// SQL Create command for certificate table.
FOUNDATION_EXPORT NSString * const PEX_UCRT_CREATE_TABLE;

@interface PEXDbUserCertificate : PEXDbModelBase
@property NSNumber * id;
@property NSString * owner;
@property NSData * certificate;
@property NSString * certificateHash;
@property NSDate * dateCreated;
@property NSNumber * certificateStatus;
@property NSDate * dateLastQuery;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(NSArray *) getNormalProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;

- (instancetype)initWithCursor:(PEXDbCursor *)cursor;
+ (instancetype)certificateWithCursor:(PEXDbCursor *)cursor;

- (PEXDbContentValues *) getDbContentValues;
- (PEXX509 *) getCertificateObj;
- (BOOL) isValidCertObj;

+(PEXDbUserCertificate *) newCertificateForUser: (NSString *) user cr: (PEXDbContentProvider *) cr projection: (NSArray *) projection;
+(NSDictionary *) loadCertificatesForUsers: (NSArray *) user cr: (PEXDbContentProvider *) cr projection: (NSArray *) projection;
+(void) updateCertificateStatus: (NSNumber *) status owner: (NSString *) owner cr: (PEXDbContentProvider *) cr;
+(int) deleteCertificateForUser: (NSString *) owner cr: (PEXDbContentProvider *) cr;
+(int) deleteCertificateForUser: (NSString *) owner cr: (PEXDbContentProvider *) cr error: (NSError **) pError;
+(int) insertUnique: (NSString *) owner cr: (PEXDbContentProvider *) cr cv: (const PEXDbContentValues * const)contentValues;
@end