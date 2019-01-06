//
// Created by Dusan Klinec on 29.06.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXContactCertificateLoadTask.h"
#import "PEXTask_Protected.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbAppContentProvider.h"
#import "PEXCryptoUtils.h"
#import "PEXMessageDigest.h"


@implementation PEXContactCertificateLoadTask {

}

/**
* Has to be overriden, if perform is called using GCD,
* NSOperationQueue refuses to start a new thread if
* perform is waiting, on some devices.
*/
- (void) start
{
    [self startedProtected];
    [self perform];

    // TODO polish overriding
    //_ended = true;
    [self endedProtected];
}

- (void) perform
{
    // Load certificate details for the user.
    PEXDbUserCertificate * uCrt = [PEXDbUserCertificate newCertificateForUser:self.userName
                                                                           cr:[PEXDbAppContentProvider instance]
                                                                   projection:[PEXDbUserCertificate getFullProjection]];
    if (uCrt == nil){
        DDLogVerbose(@"User certificate not found %@", self.userName);
        return;
    }

    @try {
        self.certDetails = [[PEXCertDetails alloc] init];
        self.certDetails.certStatus = [uCrt.certificateStatus integerValue];
        self.certDetails.dateCreated = uCrt.dateCreated;
        self.certDetails.dateLastRefresh = uCrt.dateLastQuery;

        PEXX509 * crt = uCrt.getCertificateObj;
        if (crt != nil && crt.isAllocated) {
            self.certDetails.notBefore = [PEXCryptoUtils getNotBefore:crt.getRaw];
            self.certDetails.notAfter = [PEXCryptoUtils getNotAfter:crt.getRaw];
            self.certDetails.certHash = [PEXMessageDigest getCertificateDigestWrap:crt];
            self.certDetails.certCN = [PEXCryptoUtils getCNameCrt:crt.getRaw totalCount:NULL];
        }
    } @catch(NSException * e){
        DDLogError(@"Exception in loading certificates. Exception=%@", e);
    }
}

@end

@implementation PEXCertDetails
@end