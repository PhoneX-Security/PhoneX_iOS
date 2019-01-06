//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "openssl/ossl_typ.h"
#import "openssl/x509.h"
#import "PEXRSA.h"
#import "PEXX509.h"
#import "PEXX509Req.h"

@interface PEXCertGenTaskState : NSObject
@property(atomic, readwrite) BOOL errorOccurred;
@property(atomic, readwrite) BOOL cancelDetected;
@property(atomic) NSError * lastError;

@property(nonatomic) PEXRSA * keyPair;
@property(nonatomic) PEXX509Req * csr;
@property(nonatomic) NSString * csrPem;
@property(nonatomic) NSString * userToken;
@property(nonatomic) NSString * serverToken;
@property(nonatomic) NSString * ha1;
@property(nonatomic) NSString * authToken;
@property(nonatomic) NSString * encToken;
@property(nonatomic) NSString * pemPassword;
@property(nonatomic) NSString * pkcsPassword;
@property(nonatomic) NSData * csrEncrypted;
@property(nonatomic) NSData * certificateEncrypted;
@property(nonatomic) PEXX509 * certificate;
@end