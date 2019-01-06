//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXCertificate;
@class PEXDbUserCertificate;
@class hr_getCertificateResponse;
@class PEXSOAPTask;

/**
* Certificate refresh input parameter.
*/
@interface PEXCertRefreshParams : NSObject <NSCoding, NSCopying>
/**
* User identifier for certificate refresh.
*/
@property(nonatomic) NSString * user;

/**
* Force user certificate check on the server side.
* If set to NO and certificate was checked recently, it won't be checked again.
*/
@property(nonatomic) BOOL forceRecheck;

/**
* If set to YES (default), and there is a local record for given user certificate, its hash will be used
* to query server the certificate validity. If certificate is valid, server returns simple answer and no
* more processing is needed. If useCertHash is set to NO, server is asked for DER encoded X509 certificate
* and it needs to be processed even if local certificate entry is present and valid.
*/
@property(nonatomic) BOOL useCertHash;

/**
* Hash of the existing certificate to be checked.
* If specified, this particular certificate is checked for validity. If is not valid,
* current valid certificate is returned. If is valid, lightweight confirmation is returned
* saving bandwidth.
*/
@property(nonatomic) NSString * existingCertHash2recheck;

/**
* If set to YES, certificates are loaded to the memory (results) after fetching.
*/
@property(nonatomic) BOOL loadCertificateToResult;

/**
* If set to YES, in case of a certificate update, DH keys are updated as well.
*/
@property(nonatomic) BOOL allowDhKeyRefreshOnCertChange;

/**
* If yes, new certificate is loaded from database right after it is inserted.
*/
@property(nonatomic) BOOL loadNewCertificateAfterInsert;

/**
* Fields for certificate update logic.
*/
@property (nonatomic) BOOL pushNotification; //false;
@property (nonatomic) BOOL becameOnlineCheck; //false;
@property (nonatomic) NSDate * notBefore;
@property (nonatomic) NSString * callbackId;

- (instancetype)initWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck;
+ (instancetype)paramsWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck;
- (instancetype)initWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck existingCertHash2recheck:(NSString *)existingCertHash2recheck;
+ (instancetype)paramsWithUser:(NSString *)user forceRecheck:(BOOL)forceRecheck existingCertHash2recheck:(NSString *)existingCertHash2recheck;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)copyWithZone:(NSZone *)zone;

- (NSString *)description;

@end
