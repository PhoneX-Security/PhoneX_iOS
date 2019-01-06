//
// Created by Dusan Klinec on 06.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXUtils.h"
#import "PEXDbContact.h"
#import "PEXDBUserProfile.h"
#import "PEXCertificateUpdateTask.h"
#import "PEXMessageDigest.h"
#import "PEXCryptoUtils.h"
#import "PEXSOAPTask.h"
#import "PEXDbUserCertificate.h"
#import "PEXUserPrivate.h"
#import "PEXCertRefreshTask.h"
#import "PEXCertUtils.h"
#import "hr.h"
#import "PEXX509.h"
#import "PEXDbAppContentProvider.h"
#import "PEXSecurityCenter.h"


@implementation PEXCertUtils {

}
+(int) processNewCertificate: (hr_certificateWrapper *) wr user: (NSString *) user
                       dbcrt: (PEXDbUserCertificate *) dbcrt
                      newCrt: (PEXX509 **) newCrt {
    // If we are here then
    //	a) user had no certificate stored
    //	b) or user had certificate stored, but was invalid
    // thus process this result - new certificate should be provided or error code if
    // something is wrong with certificate on server side (missing, invalid, revoked).
    NSData * cert = wr.certificate;
    __block int errorCode = 0;
    @try {
        // Store certificate to database in each case (invalid vs. ok), both is
        // useful to know. We than have fresh data stored in database (no need to re-query
        // in case of error).
        __block PEXDbUserCertificate * crt2db = dbcrt;
        crt2db.dateCreated = [NSDate date];
        crt2db.dateLastQuery = [NSDate date];
        crt2db.certificateStatus = @(wr.status);
        crt2db.owner = user;

        // Error handling block. Previously, it was an error handling macro defined here.
        // Macro had benefit there was no __block needed for internal variables, but was not transparent
        // for editor / compiler in case of errors.
        // Not the beautiful way of solving things, but simplifies the code.
        void (^certError)(int code) = ^(int code) {
            errorCode = (code);
            crt2db.certificateStatus = @(CERTIFICATE_STATUS_INVALID);
            crt2db.certificateHash = nil;
//            if (curRes != nil){
//                curRes.remoteCertObj = nil;
//                curRes.statusCode = (code);
//                if (curRes.remoteCert != nil){
//                    curRes.remoteCert.certificateStatus = crt2db.certificateStatus;
//                }
//            }
        };

        // Processing loop. Hapy code path.
        do {
            if (wr.status != CERTIFICATE_STATUS_OK) {
                // Store the error status to the memory.
                crt2db.certificateStatus = @(wr.status);
                errorCode = -8;
                break;
            }

            // Empty certificate?
            if (cert == nil || cert.length == 0){
                certError(-5);
                break;
            }

            // Create wrapper X509 certificate representation from DER.
            PEXX509 *crt = [PEXCryptoUtils importCertificateFromDERWrap:cert];
            if (!crt.isAllocated) {
                DDLogWarn(@"Problem with a certificate parsing for user %@", user);
                certError(-2);
                break;
            }

            // Check Certificate CN match to the user name.
            NSString *cnFromCert = [PEXCryptoUtils getCNameCrt:crt.getRaw totalCount:nil];
            if (![user isEqualToString:cnFromCert]) {
                DDLogError(@"Security alert! Server returned certificate with different CN!");
                certError(-3);
                break;
            } else {
                DDLogVerbose(@"Certificate CN matches for %@", cnFromCert);
            }

            // Verify new certificate with trust verifier
            BOOL crtOk = [PEXSecurityCenter tryOsslCertValidate:crt settings:[PEXCertVerifyOptions optionsWithAllowOldCaExpired:YES]];
            if (!crtOk){
                certError(-6);
                break;
            }

            // Sec: Re-export cert to DER to get rid of potential rubbish.
            NSData *certDER = [PEXCryptoUtils exportCertificateToDERWrap:crt];
            if (certDER == nil) {
                DDLogError(@"Cannot export X509 certificate to DER");
                certError(-4);
                break;
            }

            // Compute new certificate digest / hash so it is identified by it in next queries.
            NSString *certificateHash = [PEXMessageDigest getCertificateDigestDER:certDER];
            DDLogVerbose(@"Certificate digest computed: %@", certificateHash);

            // Set new certificate DER & hash to the database model.
            crt2db.certificate = certDER;
            crt2db.certificateHash = certificateHash;

            errorCode = 0;
            if (newCrt != NULL){
                *newCrt = crt;
            }
        } while (0);

    } @catch (NSException * e) {
        DDLogError(@"Exception in certificate processing thrown: %@", e);
        @throw e;
    }

    return errorCode;
}

+ (BOOL)recheckCertificateForUser:(PEXDbUserCertificate *)sipRemoteCert {
    if (sipRemoteCert == nil || sipRemoteCert.dateLastQuery == nil){
        return YES;
    }

    NSDate * lastQuery = sipRemoteCert.dateLastQuery;
    BOOL recheckNeeded = NO;

    // is certificate stored in database OK?
    if ([@(CERTIFICATE_STATUS_OK) isEqualToNumber:sipRemoteCert.certificateStatus]){
        // certificate is valid, maybe we still need some re-check (revocation status for example)
        NSDate * boundary = [NSDate dateWithTimeInterval:-CERTIFICATE_OK_RECHECK_PERIOD sinceDate:[NSDate date]];
        recheckNeeded = [lastQuery compare:boundary] == NSOrderedAscending;
    } else {
        // Certificate is invalid, missing or revoked or broken somehow.
        // should re-check be performed?
        NSDate * boundary = [NSDate dateWithTimeInterval:-CERTIFICATE_NOK_RECHECK_PERIOD sinceDate:[NSDate date]];
        recheckNeeded = [lastQuery compare:boundary] == NSOrderedAscending;
    }

    return recheckNeeded;
}

/**
* Update last certificate refresh.
*/
+(void)updateLastCertRefresh:(PEXDbContact *)cl cr: (PEXDbContentProvider *) cr {
    int newUpdateNum = 0;

    // If update is in the same day as the previous one, increment update counter.
    if (cl.presenceLastCertUpdate != nil && cl.presenceNumCertUpdate != nil){
        if ([PEXUtils isToday:cl.presenceLastCertUpdate]){
            newUpdateNum = [cl.presenceNumCertUpdate integerValue] + 1;
        }
    }

    PEXDbContentValues * dataToInsert = [[PEXDbContentValues alloc] init];
    [dataToInsert put:PEX_DBCL_FIELD_PRESENCE_NUM_CERT_UPDATE integer:newUpdateNum];
    [dataToInsert put:PEX_DBCL_FIELD_PRESENCE_LAST_CERT_UPDATE date: [NSDate date]];
    [PEXDbContact updateContact:cr contactId:cl.id contentValues:dataToInsert];
}
@end