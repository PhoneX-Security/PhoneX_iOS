//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertGenTaskState.h"
#import "PEXRSA.h"
#import "PEXX509.h"
#import "PEXX509Req.h"


@implementation PEXCertGenTaskState {

}

-(id) init {
    self = [super init];
    self.errorOccurred = NO;
    self.cancelDetected = NO;
    self.lastError = nil;

    self.authToken=nil;
    self.certificate=nil;
    self.certificateEncrypted=nil;
    self.csr=nil;
    self.csrPem=nil;
    self.csrEncrypted=nil;
    self.encToken=nil;
    self.ha1=nil;
    self.pemPassword=nil;
    self.pkcsPassword=nil;
    self.keyPair=nil;
    self.serverToken=nil;
    self.userToken=nil;

    return self;
}

@end