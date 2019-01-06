//
// Created by Dusan Klinec on 19.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDBModelBase.h"

@class PEXDbContentProvider;

FOUNDATION_EXPORT NSString * PEX_DBDH_TABLE;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_ID;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_SIP;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_PUBLIC_KEY;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_PRIVATE_KEY;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_GROUP_NUMBER;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_DATE_CREATED;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_DATE_EXPIRE;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_NONCE1;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_NONCE2;
FOUNDATION_EXPORT NSString * PEX_DBDH_FIELD_ACERT_HASH;

@interface PEXDbDhKey : PEXDbModelBase
@property(nonatomic) NSNumber * id;
@property(nonatomic) NSString * sip;
@property(nonatomic) NSString * publicKey;
@property(nonatomic) NSString * privateKey;
@property(nonatomic) NSNumber * groupNumber;
@property(nonatomic) NSDate * dateCreated;
@property(nonatomic) NSDate * dateExpire;
@property(nonatomic) NSString * nonce1;
@property(nonatomic) NSString * nonce2;
@property(nonatomic) NSString * aCertHash;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(NSArray *) getLightProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;
- (instancetype)initWithCursor: (PEXDbCursor *) c;

/**
* Looks up the DH key with given nonce2.
*
* @param cr
* @param nonce2
* @return
*/
+(instancetype) getByNonce2: (NSString *) nonce2 cr: (PEXDbContentProvider *) cr;

/**
* Deletes key corresponding to the given user with given nonce from database.
*
* @param cr
* @param nonce2
* @param user
*/
+(int) delete: (NSString *) nonce2 user: (NSString *) user cr: (PEXDbContentProvider *) cr;

/**
* Returns list of a nonce2s for ready DH keys. If
* sip is not null, for a given user, otherwise for
* everybody.
*
* @param sip OPTIONAL
* @return
*/
+(NSArray *) getReadyDHKeysNonce2: (NSString *) sip cr: (PEXDbContentProvider *) cr;

/**
* Loads specific DHkey from the database.
* Sip can be null, in that case only nonce2 is used for search.
*
* @param nonce2
* @param sip
* @return
*/
+(instancetype) loadDHKey: (NSString *) nonce2 sip: (NSString *) sip cr: (PEXDbContentProvider *) cr;

/**
* Removes all DH keys for particular user.
*
* @param sip
* @return
*/
+(int) removeDHKeysForUser: (NSString *) sip cr: (PEXDbContentProvider *) cr;

/**
* Removes a DHKey with given nonce2
*
* @param sip
* @return
*/
+(BOOL) removeDHKey: (NSString *) nonce2 cr: (PEXDbContentProvider *) cr;
+(BOOL) removeDHKeyById: (int64_t) id cr: (PEXDbContentProvider *) cr;

/**
* Removes a DHKey with given nonce2s
*
* @param sip
* @return
*/
+(int) removeDHKeys: (NSArray *) nonces cr: (PEXDbContentProvider *) cr;

/**
* Removes DH keys that are either a) older than given date
* OR b) does not have given certificate hash OR both OR just
* equals the sip.
*
* Returns number of removed entries.
*
* @param sip
* @param olderThan
* @param certHash
* @param expirationLimit
* @return
*/
+(int) removeDHKeys: (NSString *) sip olderThan: (NSDate *) olderThan certHash: (NSString *) certHash
    expirationLimit: (NSDate *) expirationLimit cr: (PEXDbContentProvider *) cr;

- (NSString *)description;
- (id)copyWithZone:(NSZone *)zone;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end