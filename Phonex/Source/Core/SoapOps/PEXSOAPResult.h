//
// Created by Dusan Klinec on 07.04.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXSOAPTask.h"

typedef enum {
    PEX_SOAP_CALL_RES_OK          = 0,
    PEX_SOAP_CALL_RES_CANCELLED   = -1,
    PEX_SOAP_CALL_RES_ERROR       = -2,
    PEX_SOAP_CALL_RES_SOAP_ERROR  = -3,
    PEX_SOAP_CALL_RES_EXCEPTION   = -10
} PEXSoapBaseResultCode;

@interface PEXSOAPResult : NSObject
@property (nonatomic) NSException * ex;
@property (nonatomic) NSError * err;
@property (nonatomic) NSInteger code;
@property (nonatomic) NSInteger responseCode;
@property (nonatomic) PEXSoapTaskErrorEnum soapTaskError;
@property (nonatomic) BOOL timeoutDetected;
@property (nonatomic) BOOL cancelDetected;

/**
* Return if operation ended up with error (does not take application error into account in general).
*/
- (BOOL) wasError;
+ (BOOL) wasError: (PEXSOAPResult *) res;

/**
* Returns YES if operation ended up with error and cause was in NSURLErrorDomain.
*/
- (BOOL) wasErrorWithConnectivity;

/**
* Sets this object to the reference given.
*/
- (void) setToRef: (PEXSOAPResult **) res;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
@end