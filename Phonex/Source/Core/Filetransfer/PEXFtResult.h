//
// Created by Dusan Klinec on 10.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXSOAPTask.h"

/**
* Result from main work procedure.
*
* @author ph4r05
*/
@interface PEXFtResult : NSObject <NSCoding, NSCopying>
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
+ (BOOL) wasError: (PEXFtResult *) res;

/**
* Returns YES if operation ended up with error and cause was in NSURLErrorDomain.
*/
- (BOOL) wasErrorWithConnectivity;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
@end