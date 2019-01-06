//
// Created by Dusan Klinec on 22.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXCertificate;
@class PEXDbUserCertificate;
@class PEXCertRefreshParams;

/**
* Result of a certificate refresh.
*/
@interface PEXCertRefreshResult : NSObject <NSCoding>
/**
* Original params of the cert request associated to this response.
*/
@property(nonatomic) PEXCertRefreshParams * params;

/**
* YES if the process was cancelled.
*/
@property(nonatomic) BOOL canceled;

/**
* Result code of the operation.
*/
@property(nonatomic) int statusCode;

/**
* Database entity corresponding to an user certificate. May be nil if there is no such certificate or in case of an error.
*/
@property(nonatomic) PEXDbUserCertificate * remoteCert;

/**
* Current valid certificate of the user. May be nil if there is no such certificate or in case of an error.
*/
@property(nonatomic) PEXCertificate * remoteCertObj;

/**
* Set by isRecheckNeeded.
*/
@property(nonatomic) NSNumber * recheckNeeded;

/**
* New certificate hash computed
*/
@property(nonatomic) NSString * certHash;

- (instancetype)initWithParams:(PEXCertRefreshParams *)params;
+ (instancetype)resultWithParams:(PEXCertRefreshParams *)params;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
@end
