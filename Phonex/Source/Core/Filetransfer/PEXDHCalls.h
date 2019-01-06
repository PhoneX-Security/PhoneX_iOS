//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

typedef enum {
    PEX_DH_CALL_RES_OK          = 0,
    PEX_DH_CALL_RES_CANCELLED   = -1,
    PEX_DH_CALL_RES_ERROR       = -2,
    PEX_DH_CALL_RES_SOAP_ERROR  = -3,
    PEX_DH_CALL_RES_EXCEPTION   = -10
} PEXDhCallResultCode;

@protocol PEXCanceller;
@class PEXSOAPTask;
@class PEXFtResult;
@class hr_ftGetStoredDHKeysInfoResponse;
@class PEXDHKeyGeneratorParams;
@class hr_ftAddDHKeysResponse;
@class hr_ftDeleteFilesResponse;
@class hr_ftGetStoredFilesResponse;
@class hr_ftGetDHKeyResponse;
@class hr_ftGetDHKeyPart2Response;

@interface PEXDHCalls : NSObject<PEXTaskListener>
/**
* User credentials for certificate check. Certificate check is user dependent.
*/
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) id<PEXCanceller> canceller;
@property(nonatomic, readonly) NSError * error;
@property(nonatomic, readonly) BOOL wasCancelled;
@property(nonatomic, readonly) PEXSOAPTask * curTask;

- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;
+ (instancetype)callsWithPrivData:(PEXUserPrivate *)privData;
- (instancetype)initWithPrivData:(PEXUserPrivate *)privData canceller:(id <PEXCanceller>)canceller;
+ (instancetype)callsWithPrivData:(PEXUserPrivate *)privData canceller:(id <PEXCanceller>)canceller;

-(void) doCancel;
-(BOOL) shouldCancel;

-(PEXFtResult *) deleteKeys: (NSDictionary *) deleteOlderForUser;
-(PEXFtResult *) deleteKeysWithParams: (PEXDHKeyGeneratorParams *) mpar;
-(PEXFtResult *) getDhKeys: (hr_ftGetStoredDHKeysInfoResponse **) body;
-(PEXFtResult *) uploadKeys:(NSArray *)keys response: (hr_ftAddDHKeysResponse **) response;
-(PEXFtResult *) deleteFileFromServer: (NSArray *) nonces2 domain: (NSString *) domain response: (hr_ftDeleteFilesResponse **) response;
-(PEXFtResult *) getStoredFiles: (NSArray *) nonces2 domain: (NSString *) domain response: (hr_ftGetStoredFilesResponse **) response;
-(PEXFtResult *) getDHKeysPart1: (NSString *) user domain: (NSString *) domain response: (hr_ftGetDHKeyResponse **) response;
-(PEXFtResult *) getDHKeysPart2: (NSString *) user nonce1: (NSString *) nonce1 domain: (NSString *) domain response: (hr_ftGetDHKeyPart2Response **) response;


@end