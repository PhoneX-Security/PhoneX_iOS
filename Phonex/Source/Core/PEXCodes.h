//
// Created by Dusan Klinec on 30.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * const PEXInputUserDomain;
FOUNDATION_EXPORT NSInteger const  PEXInputInvalidUSername;

FOUNDATION_EXPORT NSString * const PEXRuntimeDomain;
FOUNDATION_EXPORT NSString * const PEXRuntimeCryptoDomain;
FOUNDATION_EXPORT NSInteger const  PEXRuntimeCryptoException;
FOUNDATION_EXPORT NSString * const  PEXRuntimeSecurityException;
FOUNDATION_EXPORT NSString * const  PEXRuntimeException;

/**
* Used as a dictionary key for NSError. Can point to an extra NSException.
*/
FOUNDATION_EXPORT NSString * const PEXExtraException;

/**
* Used as a dictionary key for NSError. Can point to an extra NSError caused by SOAP fault.
*/
FOUNDATION_EXPORT NSString * const PEXExtraSOAPError;

/**
* Used as a dictionary key for NSError. Can point to an extra error code.
*/
FOUNDATION_EXPORT NSString * const PEXExtraSubCode;

/**
* Used as a dictionary key for NSError. Can point to an extra error message.
*/
FOUNDATION_EXPORT NSString * const PEXExtraMessage;
FOUNDATION_EXPORT NSString * const PEXExtraOriginalError;

FOUNDATION_EXPORT NSString * const PEXCallingAbstractMethodExceptionString;
FOUNDATION_EXPORT NSString * const PEXOperationCancelledExceptionString;
FOUNDATION_EXPORT NSString * const PEXNotConnectedExceptionString;
