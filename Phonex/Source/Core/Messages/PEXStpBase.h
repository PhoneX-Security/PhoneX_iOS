//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPrivateKey.h"
#import "PEXCertificate.h"
#import "PEXStp.h"

// If STP debugging is not define, disable it.
#ifndef PEX_ENABLE_STP_DEBUG_LOG
#define PEX_ENABLE_STP_DEBUG_LOG 0
#endif

@interface PEXStpBase : NSObject <PEXStp>
@property(nonatomic) NSString * sender;
@property(nonatomic) PEXPrivateKey * pk;
@property(nonatomic) PEXCertificate * remoteCert;

- (instancetype)initWithSender:(NSString *)sender pk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert;
+ (instancetype)baseWithSender:(NSString *)sender pk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert;

- (instancetype)initWithPk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert;
+ (instancetype)baseWithPk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert;

-(NSData *) createSignature: (NSData*) dataToSign error: (NSError **) pError;
-(BOOL) verifySignature: (NSData *) dataToVerify signature: (NSData *) signature error: (NSError **) pError;

@end