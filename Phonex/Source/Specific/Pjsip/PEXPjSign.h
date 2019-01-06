//
// Created by Dusan Klinec on 07.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXPjSignDefs.h"

@class PEXUserPrivate;

pj_status_t pex_sign(const esignInfo_t * sdata, hashReturn_t * hash);
int pex_verifySign(const esignInfo_t * sdata, const char * signature, const char * desc);

@interface PEXPjSign : NSObject
// TODO: refactor to multi user, currently generates signature only from one user.
@property(nonatomic) PEXUserPrivate * privData;
@property(nonatomic) dispatch_queue_t queue;

-(pj_status_t) sign: (const esignInfo_t *) sdata hash: (hashReturn_t *) hash;
-(int) verifySign: (const esignInfo_t *) sdata signature: (const char *) signature desc: (const char *) desc;

+ (PEXPjSign *)instance;

-(void) clearCertCache;
-(void) doRegister;
-(void) doUnregister;

@end