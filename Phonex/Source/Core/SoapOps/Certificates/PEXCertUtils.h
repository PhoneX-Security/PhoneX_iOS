//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class hr_certificateWrapper;
@class PEXDbUserCertificate;
@class PEXX509;
@class PEXDbContact;
@class PEXDbAppContentProvider;


@interface PEXCertUtils : NSObject
/**
* Process new certificate from certificate wrapper.
* Updates certificate database.
*/
+(int) processNewCertificate: (hr_certificateWrapper *) wr user: (NSString *) user
                       dbcrt: (PEXDbUserCertificate *) dbcrt
                      newCrt: (PEXX509 **) newCrt;

/**
* Tells whether to re-check certificate with respect to the last certificate check.
* Implements basic DoS avoidance for certificate check (not to update certificates
* too often).
*
* @param sipRemoteCert
* @return
*/
+(BOOL) recheckCertificateForUser: (PEXDbUserCertificate *) sipRemoteCert;

/**
* Update last certificate refresh database field according to policy.
* In one day counts number of certificate refreshes.
*/
+(void)updateLastCertRefresh:(PEXDbContact *)cl cr: (PEXDbContentProvider *) cr;
@end