//
// Created by Dusan Klinec on 07.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPjSign.h"
#import "PEXPjSignCode.h"
#import "PEXDbUserCertificate.h"
#import "PEXDbAppContentProvider.h"
#import "PEXUtils.h"
#import "PEXUserPrivate.h"
#import "PEXPjUtils.h"
#import "PEXCryptoUtils.h"
#import "PEXSipUri.h"
#import "USAdditions.h"
#import "NSString+DDXML.h"
#import "PEXReport.h"

#define SIGN_DESC  "SHA256withRSA"
#define SIGN_CHSET "UTF-8"

/**
* Global callback for signature module. Sign & verify methods.
* Points to C function wrappers which calls PEXPjSign methods.
*/
PEXSignCallback pex_sign_callback = {
        pex_sign,
        pex_verifySign
};

/**
* Content observer for certificate observer.
*/
@interface PEXSignCertificateObserver : NSObject <PEXContentObserver> {}
@property(nonatomic, weak) PEXPjSign * manager;
@property(nonatomic) PEXUri * destUri;
- (instancetype)initWithManager:(PEXPjSign *)manager;
+ (instancetype)observerWithManager:(PEXPjSign *)manager;
@end

@interface PEXCertRec : NSObject {}
@property(nonatomic) PEXDbUserCertificate * ucrt;
@property(nonatomic) PEXX509 * crt;

- (NSString *)description;
@end

@interface PEXPjSign () {}
@property(nonatomic) NSCache * certCache;
@property(nonatomic) PEXSignCertificateObserver * certObserver;
@property(nonatomic) BOOL registered;
@end

@implementation PEXPjSign {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.registered = NO;
        self.certCache = [[NSCache alloc] init];
        self.certCache.countLimit = 5;
        self.queue = dispatch_queue_create("sign_module", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}


+ (PEXPjSign *)instance {
    static PEXPjSign *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (void)doRegister {
    @synchronized (self) {
        if (self.registered) {
            DDLogWarn(@"Already registered");
            return;
        }

        DDLogDebug(@"<register_mod_sign>");
        PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];

        // Register certificate database observer.
        if (self.certObserver == nil) {
            self.certObserver = [PEXSignCertificateObserver observerWithManager:self];
            [cr registerObserver:self.certObserver];
        }

        pj_status_t initStatus = mod_sign_init();
        if (initStatus != PJ_SUCCESS) {
            DDLogError(@"Cannot initialize signature module, code=%d", initStatus);
            return;
        }

        mod_sign_set_callback(&pex_sign_callback);
        self.registered = YES;
        DDLogDebug(@"</register_mod_sign>");
    }
}

- (void)doUnregister {
    @synchronized (self) {
        if (!self.registered) {
            DDLogWarn(@"Already unregistered");
            return;
        }

        DDLogDebug(@"Unregistering signature module");
        mod_sign_set_callback(NULL);

        // Register certificate database observer.
        if (self.certObserver == nil) {
            self.certObserver = [PEXSignCertificateObserver observerWithManager:self];
            PEXDbContentProvider *cr = [PEXDbAppContentProvider instance];
            [cr registerObserver:self.certObserver];
        }

        self.registered = NO;
    }
}

/**
* Clears certificate cache - called on a certificate update event.
*/
-(void) clearCertCache {
    // NSCache is synchronized internally.
    [self.certCache removeAllObjects];

    DDLogDebug(@"Cert cache cleared");
}

/**
* Assumes normalized user name without scheme.
* @param user
* @return
*/
-(PEXCertRec *) getCertificate: (NSString *) user{
    // Is in LRU cache? If yes, return directly.
    // NSCache is synchronized internally.
    id sc = [self.certCache objectForKey:user];
    if (sc != nil && [sc isMemberOfClass:[PEXCertRec class]]){
        return (PEXCertRec *) sc;
    }

    PEXCertRec * rec = [[PEXCertRec alloc] init];

    // Load certificate for user from local database.
    PEXDbContentProvider * cr = [PEXDbAppContentProvider instance];
    PEXDbUserCertificate * remoteCert = [PEXDbUserCertificate newCertificateForUser: user cr:cr projection:[PEXDbUserCertificate getFullProjection]];
    if (remoteCert == nil){
        DDLogDebug(@"Certificate not found for user: %@", user);
        remoteCert = [[PEXDbUserCertificate alloc] init];
        remoteCert.certificateStatus = @(CERTIFICATE_STATUS_MISSING);
        rec.crt = nil;
    } else {
        rec.crt = [remoteCert getCertificateObj];
    }

    // NSCache is synchronized internally.
    rec.ucrt = remoteCert;
    [self.certCache setObject:rec forKey:user];

    return rec;
}

- (pj_status_t)sign:(const esignInfo_t *)sdata hash:(hashReturn_t *)hash {
    if (self.privData == nil){
        DDLogWarn(@"PrivData is null, cannot sign");
        return -1;
    }

    __block pj_status_t retStatus = 0;
    __block hashReturn_t * hashBlock = hash;
    __weak __typeof(self) weakSelf = self;

    dispatch_block_t signBlock = ^{  @autoreleasepool {
        @try {
            PEXPjSign *sg = weakSelf;
            if (sg == nil) {
                DDLogError(@"Cannot verify signature, nil weak.");
                return;
            }

            int cseqInt = sdata->cseqInt;
            NSString *method = [[PEXPjUtils copyToString:&sdata->method] stringByTrimming];
            NSString *reqUri = [[PEXPjUtils copyToString:&sdata->reqUriStr] stringByTrimming];
            NSString *fromUri = [[PEXPjUtils copyToString:&sdata->fromUriStr] stringByTrimming];
            NSString *toUri = [[PEXPjUtils copyToString:&sdata->toUriStr] stringByTrimming];
            NSString *toSign = [[PEXPjUtils copyToString:&sdata->accumStr] stringByTrimming];
            NSString *digest = [[PEXPjUtils copyToString:&sdata->accumSha256Str] stringByTrimming];

            // Logic part - do something...
            DDLogDebug(@"Sign callback called; cseq[%d] method[%@] reqUri[%@] fromUri[%@] toUri[%@] digest[%@]",
                    cseqInt,
                    method,
                    reqUri,
                    fromUri,
                    toUri,
                    digest);
            DDLogVerbose(@"Sign callback called; toSign: <<<EOF\n%@\nEOF;", toSign);

            // return in hash structure - pass multiple values back
            NSString *tmpHash = @"0000xxxx0000";
            NSString *tmpDesc = @"v1;"SIGN_DESC;
            if (sg.privData == nil) {
                DDLogError(@"Privdata is nil, cannot create a signature");

                retStatus = -2;
                hashBlock->errCode = -2;
                hashBlock->retStatus = -2;
                return;
            }

            // Sign it.
            PEXPrivateKey *pk = [[PEXPrivateKey alloc] init];
            pk.key = sg.privData.privKey;

            NSError *err = nil;
            NSData *signature = [PEXCryptoUtils sign:[digest dataUsingEncoding:NSUTF8StringEncoding] key:pk error:&err];
            if (signature == nil || err != nil) {
                DDLogError(@"Cannot create a signature, error=%@", err);

                retStatus = -2;
                hashBlock->errCode = -2;
                hashBlock->retStatus = -2;
                return;
            }

            tmpHash = [signature base64EncodedStringWithOptions:0];
            pj_strdup2_with_null(sdata->pool, &hashBlock->hash, [tmpHash cStringUsingEncoding:NSASCIIStringEncoding]);
            pj_strdup2_with_null(sdata->pool, &hashBlock->desc, [tmpDesc cStringUsingEncoding:NSASCIIStringEncoding]);
            hashBlock->errCode = 0;
            hashBlock->retStatus = PJ_SUCCESS;

        }@catch (NSException * e){
            DDLogError(@"Exception in signature block: %@", e);
            [PEXReport logError:@"signException" message:@"Could not generate signature exception" exception:e];
        }
    }};

    [PEXUtils executeOnQueue:self.queue async:NO block:signBlock];
    return retStatus;
}

- (int)verifySign:(const esignInfo_t *)sdata signature:(const char *)signature desc:(const char *)desc {
    if (self.privData == nil){
        DDLogWarn(@"PrivData is null, cannot verify signature");
        return -1;
    }

    __block BOOL drop          = YES;
    __block BOOL doDrop        = YES;
    __block int dropFlag       = 0;
    __block int returnVal      = ESIGN_SIGN_ERR_GENERIC;
    __weak __typeof(self) weakSelf = self;

    dispatch_block_t verifyBlock = ^{ @autoreleasepool {
        @try {
            PEXPjSign *sg = weakSelf;
            if (sg == nil) {
                DDLogError(@"Cannot verify signature, nil weak.");
                return;
            }

            // if no signature -> return 1, nothing to verify, show warning!
            if (signature == NULL || desc == NULL) {
                DDLogWarn(@"COuld not verify signature, it is null");
                return;
            }

            int cseqInt = sdata->cseqInt;
            NSString *method = [[PEXPjUtils copyToString:&sdata->method] stringByTrimming];
            NSString *reqUri = [[PEXPjUtils copyToString:&sdata->reqUriStr] stringByTrimming];
            NSString *fromUri = [[PEXPjUtils copyToString:&sdata->fromUriStr] stringByTrimming];
            NSString *toUri = [[PEXPjUtils copyToString:&sdata->toUriStr] stringByTrimming];
            NSString *toSign = [[PEXPjUtils copyToString:&sdata->accumStr] stringByTrimming];
            NSString *digest = [[PEXPjUtils copyToString:&sdata->accumSha256Str] stringByTrimming];
            NSString *ip = [[PEXPjUtils copyToString:&sdata->ip] stringByTrimming];

            // Derive more data.
            NSString *remoteUri = sdata->isRequest > 0 ? fromUri : toUri;
            NSString *remoteSip = [PEXSipUri getCanonicalSipContact:remoteUri includeScheme:NO];
            NSString *upMethod = [method uppercaseString];
            NSString *signatureStr = [NSString stringWithCString:signature encoding:NSASCIIStringEncoding];
            NSString *descStr = [NSString stringWithCString:desc encoding:NSASCIIStringEncoding];

            if ([@"INVITE" isEqualToString:upMethod]) {
                // TODO: lokup preferences, discover whether to drop.
                drop = YES;
            } else if ([@"BYE" isEqualToString:upMethod]) {
                // TODO: lokup preferences, discover whether to drop.
                drop = YES;
            }
            if (drop) dropFlag = EESIGN_FLAG_DROP_PACKET;

            DDLogDebug(@"SignVerify callback called; cseq[%d] method[%@] reqUri[%@] fromUri[%@] toUri[%@] digest[%@] ip[%@]",
                    cseqInt,
                    method,
                    reqUri,
                    fromUri,
                    toUri,
                    digest,
                    ip);
            DDLogDebug(@"SignVerify callback called; EESIGN=[%@] EEDESC=[%@]", signatureStr, descStr);
            DDLogDebug(@"SignVerify callback called; toSign: <<<EOF\n%@\nEOF;", toSign);

            NSString *tmpHash = digest;
            DDLogDebug(@"Computed hash on my side=[%@]; remote sip=[%@]", tmpHash, remoteSip);

            // certificate is locally cached to avoid SQLite queries.
            PEXCertRec *certRec = [sg getCertificate:remoteSip];
            if (certRec == nil
                    || certRec.ucrt == nil
                    || certRec.crt == nil
                    || ![@(CERTIFICATE_STATUS_OK) isEqualToNumber:certRec.ucrt.certificateStatus]) {
                DDLogError(@"Cannot verify signature, certificate not found or not valid, certRec=%@, user=%@", certRec, remoteSip);
                returnVal = ESIGN_SIGN_ERR_REMOTE_USER_CERT_ERR;
                doDrop = YES;
                return;
            }

            PEXX509 *crt = certRec.crt;
            PEXCertificate *pexCert = [PEXCertificate certificateWithCert:crt];
            NSError *error = nil;

            // Verify signature here.
            BOOL signatureOK = [PEXCryptoUtils verify:[tmpHash dataUsingEncoding:NSUTF8StringEncoding]
                                            signature:[NSData dataWithBase64EncodedString:signatureStr]
                                          certificate:pexCert
                                                error:&error];

            // Certificate & Signature verification block
            if (error != nil || !signatureOK) {
                DDLogWarn(@"Signature is NOT VALID!");
                returnVal = ESIGN_SIGN_ERR_SIGNATURE_INVALID;
                doDrop = YES;
            } else {
                DDLogDebug(@"Signature is OK!");
                returnVal = ESIGN_SIGN_ERR_SUCCESS;
                doDrop = NO;
            }

        } @catch(NSException * e){
            DDLogError(@"Exception when veryfying a signature %@", e);
            [PEXReport logError:@"verifyException" message:@"Could not verify signature exception" exception:e];
        }
    }};

    // Execute and evaluate.
    [PEXUtils executeOnQueue:self.queue async:NO block:verifyBlock];
    return doDrop ? (returnVal | dropFlag) : returnVal;
}

@end

// Implementation of the certificate content observer.
// Idea: Flush certificate cache on certificate update.
@implementation PEXSignCertificateObserver
- (instancetype)initWithManager:(PEXPjSign *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
        self.destUri = [PEXDbUserCertificate getURI];
    }

    return self;
}

+ (instancetype)observerWithManager:(PEXPjSign *)manager {
    return [[self alloc] initWithManager:manager];
}

- (bool)deliverSelfNotifications {
    return false;
}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {
    PEXPjSign * sMgr = self.manager;
    if (sMgr == nil || ![self.destUri matchesBase:uri]) {
        return;
    }

    [PEXUtils executeOnQueue:sMgr.queue async:YES block:^{
        [sMgr clearCertCache];
    }];
}
@end

@implementation PEXCertRec
- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.ucrt=%@", self.ucrt];
    [description appendFormat:@", self.crt=%@", self.crt];
    [description appendString:@">"];
    return description;
}
@end

pj_status_t pex_sign(const esignInfo_t * sdata, hashReturn_t * hash){
    return [[PEXPjSign instance] sign:sdata hash:hash];
}

int pex_verifySign(const esignInfo_t * sdata, const char * signature, const char * desc){
    return [[PEXPjSign instance] verifySign:sdata signature:signature desc:desc];
}

