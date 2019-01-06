#import "PhoenixPortServiceSvc.h"
#import "PEXCryptoUtils.h"
#import "PEXServiceConstants.h"
#import <libxml/xmlstring.h>
#if TARGET_OS_IPHONE
#import <CFNetwork/CFNetwork.h>
#endif
#ifndef ADVANCED_AUTHENTICATION
#define ADVANCED_AUTHENTICATION 0
#endif
#if ADVANCED_AUTHENTICATION && TARGET_OS_IPHONE
#import <Security/Security.h>
#endif
@implementation PhoenixPortServiceSvc
+ (void)initialize
{
	[[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"xs" forKey:@"http://www.w3.org/2001/XMLSchema"];
	[[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"PhoenixPortServiceSvc" forKey:@"http://phoenix.com/hr/definitions"];
	[[USGlobals sharedInstance].wsdlStandardNamespaces setObject:@"hr" forKey:@"http://phoenix.com/hr/schemas"];
}
+ (PhoenixPortSoap11Binding *)PhoenixPortSoap11Binding
{
	return [self PhoenixPortSoap11Binding:NO];
}
+ (PhoenixPortSoap11Binding *)PhoenixPortSoap11Binding:(BOOL)withClientCertificate {
    uint portNumber = withClientCertificate ? PEX_SERVICE_PORT : PEX_SERVICE_PORT_NO_CERT;
    uint32_t r = [PEXCryptoUtils secureRandomUInt32:NO];
    NSString * address = [NSString stringWithFormat:@"https://phone-x.net:%d/phoenix/phoenixService/phoenix.wsdl#%u", portNumber, r];
    return [[PhoenixPortSoap11Binding alloc] initWithAddress:address];
}
@end
@implementation PhoenixPortSoap11Binding
@synthesize address;
@synthesize timeout;
@synthesize logXMLInOut;
@synthesize ignoreEmptyResponse;
@synthesize cookies;
@synthesize customHeaders;
@synthesize soapSigner;
@synthesize sslManager;
+ (NSTimeInterval)defaultTimeout
{
    return 20;
}
- (id)init
{
    if((self = [super init])) {
        address = nil;
        cookies = nil;
        customHeaders = [NSMutableDictionary new];
        timeout = [[self class] defaultTimeout];
        logXMLInOut = NO;
        synchronousOperationComplete = NO;
    }

    return self;
}
- (id)initWithAddress:(NSString *)anAddress
{
    if((self = [self init])) {
        self.address = [NSURL URLWithString:anAddress];
    }

    return self;
}
- (NSString *)MIMEType
{
    return @"text/xml";
}
- (void)addCookie:(NSHTTPCookie *)toAdd
{
    if(toAdd != nil) {
        if(cookies == nil) cookies = [[NSMutableArray alloc] init];
        [cookies addObject:toAdd];
    }
}
- (PhoenixPortSoap11BindingResponse *)performSynchronousOperation:(PhoenixPortSoap11BindingOperation *)operation
{
    synchronousOperationComplete = NO;
    [operation start];

    // Now wait for response
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];

    while (!synchronousOperationComplete && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    return operation.response;
}
- (void)performAsynchronousOperation:(PhoenixPortSoap11BindingOperation *)operation
{
    [operation start];
}
- (void) operation:(PhoenixPortSoap11BindingOperation *)operation completedWithResponse:(PhoenixPortSoap11BindingResponse *)response
{
    synchronousOperationComplete = YES;
}
- (PhoenixPortSoap11BindingResponse *)accountingFetchUsingAccountingFetchRequest:(hr_accountingFetchRequest *)aAccountingFetchRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_accountingFetch*)[PhoenixPortSoap11Binding_accountingFetch alloc] initWithBinding:self delegate:self
                                                                                                                                   accountingFetchRequest:aAccountingFetchRequest
    ]];
}
- (void)accountingFetchAsyncUsingAccountingFetchRequest:(hr_accountingFetchRequest *)aAccountingFetchRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_accountingFetch*)[PhoenixPortSoap11Binding_accountingFetch alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                              accountingFetchRequest:aAccountingFetchRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)cgroupUpdateUsingCgroupUpdateRequest:(hr_cgroupUpdateRequest *)aCgroupUpdateRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_cgroupUpdate*)[PhoenixPortSoap11Binding_cgroupUpdate alloc] initWithBinding:self delegate:self
                                                                                                                                cgroupUpdateRequest:aCgroupUpdateRequest
    ]];
}
- (void)cgroupUpdateAsyncUsingCgroupUpdateRequest:(hr_cgroupUpdateRequest *)aCgroupUpdateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_cgroupUpdate*)[PhoenixPortSoap11Binding_cgroupUpdate alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                           cgroupUpdateRequest:aCgroupUpdateRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)pairingRequestUpdateUsingPairingRequestUpdateRequest:(hr_pairingRequestUpdateRequest *)aPairingRequestUpdateRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_pairingRequestUpdate*)[PhoenixPortSoap11Binding_pairingRequestUpdate alloc] initWithBinding:self delegate:self
                                                                                                                                        pairingRequestUpdateRequest:aPairingRequestUpdateRequest
    ]];
}
- (void)pairingRequestUpdateAsyncUsingPairingRequestUpdateRequest:(hr_pairingRequestUpdateRequest *)aPairingRequestUpdateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_pairingRequestUpdate*)[PhoenixPortSoap11Binding_pairingRequestUpdate alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                   pairingRequestUpdateRequest:aPairingRequestUpdateRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)passwordChangeV2UsingPasswordChangeV2Request:(hr_passwordChangeV2Request *)aPasswordChangeV2Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_passwordChangeV2*)[PhoenixPortSoap11Binding_passwordChangeV2 alloc] initWithBinding:self delegate:self
                                                                                                                                    passwordChangeV2Request:aPasswordChangeV2Request
    ]];
}
- (void)passwordChangeV2AsyncUsingPasswordChangeV2Request:(hr_passwordChangeV2Request *)aPasswordChangeV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_passwordChangeV2*)[PhoenixPortSoap11Binding_passwordChangeV2 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                               passwordChangeV2Request:aPasswordChangeV2Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)getCertificateUsingGetCertificateRequest:(hr_getCertificateRequest *)aGetCertificateRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_getCertificate*)[PhoenixPortSoap11Binding_getCertificate alloc] initWithBinding:self delegate:self
                                                                                                                                  getCertificateRequest:aGetCertificateRequest
    ]];
}
- (void)getCertificateAsyncUsingGetCertificateRequest:(hr_getCertificateRequest *)aGetCertificateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_getCertificate*)[PhoenixPortSoap11Binding_getCertificate alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                             getCertificateRequest:aGetCertificateRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)pairingRequestInsertUsingPairingRequestInsertRequest:(hr_pairingRequestInsertRequest *)aPairingRequestInsertRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_pairingRequestInsert*)[PhoenixPortSoap11Binding_pairingRequestInsert alloc] initWithBinding:self delegate:self
                                                                                                                                        pairingRequestInsertRequest:aPairingRequestInsertRequest
    ]];
}
- (void)pairingRequestInsertAsyncUsingPairingRequestInsertRequest:(hr_pairingRequestInsertRequest *)aPairingRequestInsertRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_pairingRequestInsert*)[PhoenixPortSoap11Binding_pairingRequestInsert alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                   pairingRequestInsertRequest:aPairingRequestInsertRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftAddDHKeysUsingFtAddDHKeysRequest:(hr_ftAddDHKeysRequest *)aFtAddDHKeysRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftAddDHKeys*)[PhoenixPortSoap11Binding_ftAddDHKeys alloc] initWithBinding:self delegate:self
                                                                                                                               ftAddDHKeysRequest:aFtAddDHKeysRequest
    ]];
}
- (void)ftAddDHKeysAsyncUsingFtAddDHKeysRequest:(hr_ftAddDHKeysRequest *)aFtAddDHKeysRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftAddDHKeys*)[PhoenixPortSoap11Binding_ftAddDHKeys alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                          ftAddDHKeysRequest:aFtAddDHKeysRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftGetDHKeyUsingFtGetDHKeyRequest:(hr_ftGetDHKeyRequest *)aFtGetDHKeyRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftGetDHKey*)[PhoenixPortSoap11Binding_ftGetDHKey alloc] initWithBinding:self delegate:self
                                                                                                                              ftGetDHKeyRequest:aFtGetDHKeyRequest
    ]];
}
- (void)ftGetDHKeyAsyncUsingFtGetDHKeyRequest:(hr_ftGetDHKeyRequest *)aFtGetDHKeyRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftGetDHKey*)[PhoenixPortSoap11Binding_ftGetDHKey alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                         ftGetDHKeyRequest:aFtGetDHKeyRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftDeleteFilesUsingFtDeleteFilesRequest:(hr_ftDeleteFilesRequest *)aFtDeleteFilesRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftDeleteFiles*)[PhoenixPortSoap11Binding_ftDeleteFiles alloc] initWithBinding:self delegate:self
                                                                                                                                 ftDeleteFilesRequest:aFtDeleteFilesRequest
    ]];
}
- (void)ftDeleteFilesAsyncUsingFtDeleteFilesRequest:(hr_ftDeleteFilesRequest *)aFtDeleteFilesRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftDeleteFiles*)[PhoenixPortSoap11Binding_ftDeleteFiles alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                            ftDeleteFilesRequest:aFtDeleteFilesRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)whitelistUsingWhitelistRequest:(hr_whitelistRequest *)aWhitelistRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_whitelist*)[PhoenixPortSoap11Binding_whitelist alloc] initWithBinding:self delegate:self
                                                                                                                             whitelistRequest:aWhitelistRequest
    ]];
}
- (void)whitelistAsyncUsingWhitelistRequest:(hr_whitelistRequest *)aWhitelistRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_whitelist*)[PhoenixPortSoap11Binding_whitelist alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                        whitelistRequest:aWhitelistRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)whitelistGetUsingWhitelistGetRequest:(hr_whitelistGetRequest *)aWhitelistGetRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_whitelistGet*)[PhoenixPortSoap11Binding_whitelistGet alloc] initWithBinding:self delegate:self
                                                                                                                                whitelistGetRequest:aWhitelistGetRequest
    ]];
}
- (void)whitelistGetAsyncUsingWhitelistGetRequest:(hr_whitelistGetRequest *)aWhitelistGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_whitelistGet*)[PhoenixPortSoap11Binding_whitelistGet alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                           whitelistGetRequest:aWhitelistGetRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftGetStoredFilesUsingFtGetStoredFilesRequest:(hr_ftGetStoredFilesRequest *)aFtGetStoredFilesRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftGetStoredFiles*)[PhoenixPortSoap11Binding_ftGetStoredFiles alloc] initWithBinding:self delegate:self
                                                                                                                                    ftGetStoredFilesRequest:aFtGetStoredFilesRequest
    ]];
}
- (void)ftGetStoredFilesAsyncUsingFtGetStoredFilesRequest:(hr_ftGetStoredFilesRequest *)aFtGetStoredFilesRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftGetStoredFiles*)[PhoenixPortSoap11Binding_ftGetStoredFiles alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                               ftGetStoredFilesRequest:aFtGetStoredFilesRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)signCertificateV2UsingSignCertificateV2Request:(hr_signCertificateV2Request *)aSignCertificateV2Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_signCertificateV2*)[PhoenixPortSoap11Binding_signCertificateV2 alloc] initWithBinding:self delegate:self
                                                                                                                                     signCertificateV2Request:aSignCertificateV2Request
    ]];
}
- (void)signCertificateV2AsyncUsingSignCertificateV2Request:(hr_signCertificateV2Request *)aSignCertificateV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_signCertificateV2*)[PhoenixPortSoap11Binding_signCertificateV2 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                signCertificateV2Request:aSignCertificateV2Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)generalUsingGeneralRequest:(hr_generalRequest *)aGeneralRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_general*)[PhoenixPortSoap11Binding_general alloc] initWithBinding:self delegate:self
                                                                                                                           generalRequest:aGeneralRequest
    ]];
}
- (void)generalAsyncUsingGeneralRequest:(hr_generalRequest *)aGeneralRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_general*)[PhoenixPortSoap11Binding_general alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                      generalRequest:aGeneralRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)getOneTimeTokenUsingGetOneTimeTokenRequest:(hr_getOneTimeTokenRequest *)aGetOneTimeTokenRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_getOneTimeToken*)[PhoenixPortSoap11Binding_getOneTimeToken alloc] initWithBinding:self delegate:self
                                                                                                                                   getOneTimeTokenRequest:aGetOneTimeTokenRequest
    ]];
}
- (void)getOneTimeTokenAsyncUsingGetOneTimeTokenRequest:(hr_getOneTimeTokenRequest *)aGetOneTimeTokenRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_getOneTimeToken*)[PhoenixPortSoap11Binding_getOneTimeToken alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                              getOneTimeTokenRequest:aGetOneTimeTokenRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)pushRequestUsingPushRequestRequest:(hr_pushRequestRequest *)aPushRequestRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_pushRequest*)[PhoenixPortSoap11Binding_pushRequest alloc] initWithBinding:self delegate:self
                                                                                                                               pushRequestRequest:aPushRequestRequest
    ]];
}
- (void)pushRequestAsyncUsingPushRequestRequest:(hr_pushRequestRequest *)aPushRequestRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_pushRequest*)[PhoenixPortSoap11Binding_pushRequest alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                          pushRequestRequest:aPushRequestRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftRemoveDHKeysUsingFtRemoveDHKeysRequest:(hr_ftRemoveDHKeysRequest *)aFtRemoveDHKeysRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftRemoveDHKeys*)[PhoenixPortSoap11Binding_ftRemoveDHKeys alloc] initWithBinding:self delegate:self
                                                                                                                                  ftRemoveDHKeysRequest:aFtRemoveDHKeysRequest
    ]];
}
- (void)ftRemoveDHKeysAsyncUsingFtRemoveDHKeysRequest:(hr_ftRemoveDHKeysRequest *)aFtRemoveDHKeysRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftRemoveDHKeys*)[PhoenixPortSoap11Binding_ftRemoveDHKeys alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                             ftRemoveDHKeysRequest:aFtRemoveDHKeysRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)clistChangeV2UsingClistChangeV2Request:(hr_clistChangeV2Request *)aClistChangeV2Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_clistChangeV2*)[PhoenixPortSoap11Binding_clistChangeV2 alloc] initWithBinding:self delegate:self
                                                                                                                                 clistChangeV2Request:aClistChangeV2Request
    ]];
}
- (void)clistChangeV2AsyncUsingClistChangeV2Request:(hr_clistChangeV2Request *)aClistChangeV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_clistChangeV2*)[PhoenixPortSoap11Binding_clistChangeV2 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                            clistChangeV2Request:aClistChangeV2Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)authStateSaveV1UsingAuthStateSaveV1Request:(hr_authStateSaveV1Request *)aAuthStateSaveV1Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_authStateSaveV1*)[PhoenixPortSoap11Binding_authStateSaveV1 alloc] initWithBinding:self delegate:self
                                                                                                                                   authStateSaveV1Request:aAuthStateSaveV1Request
    ]];
}
- (void)authStateSaveV1AsyncUsingAuthStateSaveV1Request:(hr_authStateSaveV1Request *)aAuthStateSaveV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_authStateSaveV1*)[PhoenixPortSoap11Binding_authStateSaveV1 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                              authStateSaveV1Request:aAuthStateSaveV1Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)contactlistChangeUsingContactlistChangeRequest:(hr_contactlistChangeRequest *)aContactlistChangeRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_contactlistChange*)[PhoenixPortSoap11Binding_contactlistChange alloc] initWithBinding:self delegate:self
                                                                                                                                     contactlistChangeRequest:aContactlistChangeRequest
    ]];
}
- (void)contactlistChangeAsyncUsingContactlistChangeRequest:(hr_contactlistChangeRequest *)aContactlistChangeRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_contactlistChange*)[PhoenixPortSoap11Binding_contactlistChange alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                contactlistChangeRequest:aContactlistChangeRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)signCertificateUsingSignCertificateRequest:(hr_signCertificateRequest *)aSignCertificateRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_signCertificate*)[PhoenixPortSoap11Binding_signCertificate alloc] initWithBinding:self delegate:self
                                                                                                                                   signCertificateRequest:aSignCertificateRequest
    ]];
}
- (void)signCertificateAsyncUsingSignCertificateRequest:(hr_signCertificateRequest *)aSignCertificateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_signCertificate*)[PhoenixPortSoap11Binding_signCertificate alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                              signCertificateRequest:aSignCertificateRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftGetDHKeyPart2UsingFtGetDHKeyPart2Request:(hr_ftGetDHKeyPart2Request *)aFtGetDHKeyPart2Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftGetDHKeyPart2*)[PhoenixPortSoap11Binding_ftGetDHKeyPart2 alloc] initWithBinding:self delegate:self
                                                                                                                                   ftGetDHKeyPart2Request:aFtGetDHKeyPart2Request
    ]];
}
- (void)ftGetDHKeyPart2AsyncUsingFtGetDHKeyPart2Request:(hr_ftGetDHKeyPart2Request *)aFtGetDHKeyPart2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftGetDHKeyPart2*)[PhoenixPortSoap11Binding_ftGetDHKeyPart2 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                              ftGetDHKeyPart2Request:aFtGetDHKeyPart2Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)contactlistGetUsingContactlistGetRequest:(hr_contactlistGetRequest *)aContactlistGetRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_contactlistGet*)[PhoenixPortSoap11Binding_contactlistGet alloc] initWithBinding:self delegate:self
                                                                                                                                  contactlistGetRequest:aContactlistGetRequest
    ]];
}
- (void)contactlistGetAsyncUsingContactlistGetRequest:(hr_contactlistGetRequest *)aContactlistGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_contactlistGet*)[PhoenixPortSoap11Binding_contactlistGet alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                             contactlistGetRequest:aContactlistGetRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)pairingRequestFetchUsingPairingRequestFetchRequest:(hr_pairingRequestFetchRequest *)aPairingRequestFetchRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_pairingRequestFetch*)[PhoenixPortSoap11Binding_pairingRequestFetch alloc] initWithBinding:self delegate:self
                                                                                                                                       pairingRequestFetchRequest:aPairingRequestFetchRequest
    ]];
}
- (void)pairingRequestFetchAsyncUsingPairingRequestFetchRequest:(hr_pairingRequestFetchRequest *)aPairingRequestFetchRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_pairingRequestFetch*)[PhoenixPortSoap11Binding_pairingRequestFetch alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                  pairingRequestFetchRequest:aPairingRequestFetchRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)cgroupGetUsingCgroupGetRequest:(hr_cgroupGetRequest *)aCgroupGetRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_cgroupGet*)[PhoenixPortSoap11Binding_cgroupGet alloc] initWithBinding:self delegate:self
                                                                                                                             cgroupGetRequest:aCgroupGetRequest
    ]];
}
- (void)cgroupGetAsyncUsingCgroupGetRequest:(hr_cgroupGetRequest *)aCgroupGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_cgroupGet*)[PhoenixPortSoap11Binding_cgroupGet alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                        cgroupGetRequest:aCgroupGetRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)trialEventSaveUsingTrialEventSaveRequest:(hr_trialEventSaveRequest *)aTrialEventSaveRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_trialEventSave*)[PhoenixPortSoap11Binding_trialEventSave alloc] initWithBinding:self delegate:self
                                                                                                                                  trialEventSaveRequest:aTrialEventSaveRequest
    ]];
}
- (void)trialEventSaveAsyncUsingTrialEventSaveRequest:(hr_trialEventSaveRequest *)aTrialEventSaveRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_trialEventSave*)[PhoenixPortSoap11Binding_trialEventSave alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                             trialEventSaveRequest:aTrialEventSaveRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)trialEventGetUsingTrialEventGetRequest:(hr_trialEventGetRequest *)aTrialEventGetRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_trialEventGet*)[PhoenixPortSoap11Binding_trialEventGet alloc] initWithBinding:self delegate:self
                                                                                                                                 trialEventGetRequest:aTrialEventGetRequest
    ]];
}
- (void)trialEventGetAsyncUsingTrialEventGetRequest:(hr_trialEventGetRequest *)aTrialEventGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_trialEventGet*)[PhoenixPortSoap11Binding_trialEventGet alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                            trialEventGetRequest:aTrialEventGetRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)accountSettingsUpdateV1UsingAccountSettingsUpdateV1Request:(hr_accountSettingsUpdateV1Request *)aAccountSettingsUpdateV1Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_accountSettingsUpdateV1*)[PhoenixPortSoap11Binding_accountSettingsUpdateV1 alloc] initWithBinding:self delegate:self
                                                                                                                                           accountSettingsUpdateV1Request:aAccountSettingsUpdateV1Request
    ]];
}
- (void)accountSettingsUpdateV1AsyncUsingAccountSettingsUpdateV1Request:(hr_accountSettingsUpdateV1Request *)aAccountSettingsUpdateV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_accountSettingsUpdateV1*)[PhoenixPortSoap11Binding_accountSettingsUpdateV1 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                      accountSettingsUpdateV1Request:aAccountSettingsUpdateV1Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)authCheckV3UsingAuthCheckV3Request:(hr_authCheckV3Request *)aAuthCheckV3Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_authCheckV3*)[PhoenixPortSoap11Binding_authCheckV3 alloc] initWithBinding:self delegate:self
                                                                                                                               authCheckV3Request:aAuthCheckV3Request
    ]];
}
- (void)authCheckV3AsyncUsingAuthCheckV3Request:(hr_authCheckV3Request *)aAuthCheckV3Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_authCheckV3*)[PhoenixPortSoap11Binding_authCheckV3 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                          authCheckV3Request:aAuthCheckV3Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)clistGetV2UsingClistGetV2Request:(hr_clistGetV2Request *)aClistGetV2Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_clistGetV2*)[PhoenixPortSoap11Binding_clistGetV2 alloc] initWithBinding:self delegate:self
                                                                                                                              clistGetV2Request:aClistGetV2Request
    ]];
}
- (void)clistGetV2AsyncUsingClistGetV2Request:(hr_clistGetV2Request *)aClistGetV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_clistGetV2*)[PhoenixPortSoap11Binding_clistGetV2 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                         clistGetV2Request:aClistGetV2Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)pushAckUsingPushAckRequest:(hr_pushAckRequest *)aPushAckRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_pushAck*)[PhoenixPortSoap11Binding_pushAck alloc] initWithBinding:self delegate:self
                                                                                                                           pushAckRequest:aPushAckRequest
    ]];
}
- (void)pushAckAsyncUsingPushAckRequest:(hr_pushAckRequest *)aPushAckRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_pushAck*)[PhoenixPortSoap11Binding_pushAck alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                      pushAckRequest:aPushAckRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)accountingSaveUsingAccountingSaveRequest:(hr_accountingSaveRequest *)aAccountingSaveRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_accountingSave*)[PhoenixPortSoap11Binding_accountingSave alloc] initWithBinding:self delegate:self
                                                                                                                                  accountingSaveRequest:aAccountingSaveRequest
    ]];
}
- (void)accountingSaveAsyncUsingAccountingSaveRequest:(hr_accountingSaveRequest *)aAccountingSaveRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_accountingSave*)[PhoenixPortSoap11Binding_accountingSave alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                             accountingSaveRequest:aAccountingSaveRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)ftGetStoredDHKeysInfoUsingFtGetStoredDHKeysInfoRequest:(hr_ftGetStoredDHKeysInfoRequest *)aFtGetStoredDHKeysInfoRequest
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo*)[PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo alloc] initWithBinding:self delegate:self
                                                                                                                                         ftGetStoredDHKeysInfoRequest:aFtGetStoredDHKeysInfoRequest
    ]];
}
- (void)ftGetStoredDHKeysInfoAsyncUsingFtGetStoredDHKeysInfoRequest:(hr_ftGetStoredDHKeysInfoRequest *)aFtGetStoredDHKeysInfoRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo*)[PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                                    ftGetStoredDHKeysInfoRequest:aFtGetStoredDHKeysInfoRequest
    ]];
}
- (PhoenixPortSoap11BindingResponse *)accountInfoV1UsingAccountInfoV1Request:(hr_accountInfoV1Request *)aAccountInfoV1Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_accountInfoV1*)[PhoenixPortSoap11Binding_accountInfoV1 alloc] initWithBinding:self delegate:self
                                                                                                                                 accountInfoV1Request:aAccountInfoV1Request
    ]];
}
- (void)accountInfoV1AsyncUsingAccountInfoV1Request:(hr_accountInfoV1Request *)aAccountInfoV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_accountInfoV1*)[PhoenixPortSoap11Binding_accountInfoV1 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                            accountInfoV1Request:aAccountInfoV1Request
    ]];
}
- (PhoenixPortSoap11BindingResponse *)authStateFetchV1UsingAuthStateFetchV1Request:(hr_authStateFetchV1Request *)aAuthStateFetchV1Request
{
    return [self performSynchronousOperation:[(PhoenixPortSoap11Binding_authStateFetchV1*)[PhoenixPortSoap11Binding_authStateFetchV1 alloc] initWithBinding:self delegate:self
                                                                                                                                    authStateFetchV1Request:aAuthStateFetchV1Request
    ]];
}
- (void)authStateFetchV1AsyncUsingAuthStateFetchV1Request:(hr_authStateFetchV1Request *)aAuthStateFetchV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
{
    [self performAsynchronousOperation: [(PhoenixPortSoap11Binding_authStateFetchV1*)[PhoenixPortSoap11Binding_authStateFetchV1 alloc] initWithBinding:self delegate:responseDelegate
                                                                                                                               authStateFetchV1Request:aAuthStateFetchV1Request
    ]];
}
- (void)sendHTTPCallUsingBody:(NSString *)outputBody soapAction:(NSString *)soapAction forOperation:(PhoenixPortSoap11BindingOperation *)operation
{
    if (!outputBody) {
        NSError * err = [NSError errorWithDomain:@"PhoenixPortSoap11BindingNULLRequestExcpetion"
                                            code:0
                                        userInfo:nil];

        [operation connection:nil didFailWithError:err];
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.address
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:self.timeout];
    NSData *bodyData = [outputBody dataUsingEncoding:NSUTF8StringEncoding];

    if(cookies != nil) {
        [request setAllHTTPHeaderFields:[NSHTTPCookie requestHeaderFieldsWithCookies:cookies]];
    }
    [request setValue:@"wsdl2objc" forHTTPHeaderField:@"User-Agent"];
    [request setValue:soapAction forHTTPHeaderField:@"SOAPAction"];
    [request setValue:[[self MIMEType] stringByAppendingString:@"; charset=utf-8"] forHTTPHeaderField:@"Content-Type"];
    // ERICBE: cast to unsigned long to prevent warnings about implicit cast of NSInteger
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [bodyData length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:self.address.host forHTTPHeaderField:@"Host"];
    for (NSString *eachHeaderField in [self.customHeaders allKeys]) {
        [request setValue:[self.customHeaders objectForKey:eachHeaderField] forHTTPHeaderField:eachHeaderField];
    }
    [request setHTTPMethod: @"POST"];
    // set version 1.1 - how?
    [request setHTTPBody: bodyData];

    if(self.logXMLInOut) {
        DDLogVerbose(@"OutputHeaders:\n%@", [request allHTTPHeaderFields]);
        DDLogVerbose(@"OutputBody:\n%@", outputBody);
    }

    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:operation];

    operation.urlConnection = connection;
    //[connection release];
}
//- (void) dealloc
//{
//	//[soapSigner release];
//	// ERICBE: Assign sslManager property to nil to release it - avoids a compiler warning.
//	// [sslManager release];
//	self.sslManager = nil;
//	//address release];
//	//[cookies release];
//	//[customHeaders release];
//	[super dealloc];
//}
@end
@implementation PhoenixPortSoap11BindingOperation
@synthesize binding;
@synthesize response;
@synthesize delegate;
@synthesize responseData;
@synthesize urlConnection;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
{
    if ((self = [super init])) {
        self.binding = aBinding;
        response = nil;
        self.delegate = aDelegate;
        self.responseData = nil;
        self.urlConnection = nil;
    }

    return self;
}
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [binding.sslManager canAuthenticateForAuthenticationMethod:protectionSpace.authenticationMethod];
}
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (![binding.sslManager authenticateForChallenge:challenge]) {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)urlResponse
{
    NSHTTPURLResponse *httpResponse;
    if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        httpResponse = (NSHTTPURLResponse *) urlResponse;
    } else {
        httpResponse = nil;
    }

    if(self.binding.logXMLInOut) {
        DDLogVerbose(@"ResponseStatus: %ld\n", (long)[httpResponse statusCode]);
        DDLogVerbose(@"ResponseHeaders:\n%@", [httpResponse allHeaderFields]);
    }
    NSInteger contentLength = [[[httpResponse allHeaderFields] objectForKey:@"Content-Length"] integerValue];

    if ([urlResponse.MIMEType rangeOfString:[self.binding MIMEType]].length == 0) {
        if ((self.binding.ignoreEmptyResponse == NO) || (contentLength != 0)) {
            NSError *error = nil;
            [connection cancel];
            if ([httpResponse statusCode] >= 400) {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[NSHTTPURLResponse localizedStringForStatusCode:[httpResponse statusCode]],NSLocalizedDescriptionKey,
                                                                                    httpResponse.URL, NSURLErrorKey,nil];
                error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseHTTP" code:[httpResponse statusCode] userInfo:userInfo];
            } else {
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                        [NSString stringWithFormat: @"Unexpected response MIME type to SOAP call:%@", urlResponse.MIMEType],NSLocalizedDescriptionKey,
                        httpResponse.URL, NSURLErrorKey,nil];
                error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseHTTP" code:1 userInfo:userInfo];
            }

            [self connection:connection didFailWithError:error];
        } else {
            [delegate operation:self completedWithResponse:response];
        }
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (responseData == nil) {
        responseData = [data mutableCopy];
    } else {
        [responseData appendData:data];
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (binding.logXMLInOut) {
        DDLogVerbose(@"ResponseError:\n%@", error);
    }
    response.error = error;
    if (delegate == nil){
        DDLogError(@"Delegate is nill-ed");
        return;
    }
    [delegate operation:self completedWithResponse:response];
}
//- (void)dealloc
//{
//	//[binding release];
//	//[response release];
//	delegate = nil;
//	//[responseData release];
//	//[urlConnection release];
//
//	[super dealloc];
//}
@end
@implementation PhoenixPortSoap11Binding_accountingFetch
@synthesize accountingFetchRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        accountingFetchRequest:(hr_accountingFetchRequest *)aAccountingFetchRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.accountingFetchRequest = aAccountingFetchRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(accountingFetchRequest != nil) obj = accountingFetchRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"accountingFetchRequest"];
        [bodyKeys addObject:@"accountingFetchRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "accountingFetchResponse")) {
                                    hr_accountingFetchResponse *bodyObject = [hr_accountingFetchResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_cgroupUpdate
@synthesize cgroupUpdateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
  cgroupUpdateRequest:(hr_cgroupUpdateRequest *)aCgroupUpdateRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.cgroupUpdateRequest = aCgroupUpdateRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(cgroupUpdateRequest != nil) obj = cgroupUpdateRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"cgroupUpdateRequest"];
        [bodyKeys addObject:@"cgroupUpdateRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "cgroupUpdateResponse")) {
                                    hr_cgroupUpdateResponse *bodyObject = [hr_cgroupUpdateResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_pairingRequestUpdate
@synthesize pairingRequestUpdateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        pairingRequestUpdateRequest:(hr_pairingRequestUpdateRequest *)aPairingRequestUpdateRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.pairingRequestUpdateRequest = aPairingRequestUpdateRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(pairingRequestUpdateRequest != nil) obj = pairingRequestUpdateRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"pairingRequestUpdateRequest"];
        [bodyKeys addObject:@"pairingRequestUpdateRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "pairingRequestUpdateResponse")) {
                                    hr_pairingRequestUpdateResponse *bodyObject = [hr_pairingRequestUpdateResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_passwordChangeV2
@synthesize passwordChangeV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        passwordChangeV2Request:(hr_passwordChangeV2Request *)aPasswordChangeV2Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.passwordChangeV2Request = aPasswordChangeV2Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(passwordChangeV2Request != nil) obj = passwordChangeV2Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"passwordChangeV2Request"];
        [bodyKeys addObject:@"passwordChangeV2Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "passwordChangeV2Response")) {
                                    hr_passwordChangeV2Response *bodyObject = [hr_passwordChangeV2Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_getCertificate
@synthesize getCertificateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
getCertificateRequest:(hr_getCertificateRequest *)aGetCertificateRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.getCertificateRequest = aGetCertificateRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(getCertificateRequest != nil) obj = getCertificateRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"getCertificateRequest"];
        [bodyKeys addObject:@"getCertificateRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "getCertificateResponse")) {
                                    hr_getCertificateResponse *bodyObject = [hr_getCertificateResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_pairingRequestInsert
@synthesize pairingRequestInsertRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        pairingRequestInsertRequest:(hr_pairingRequestInsertRequest *)aPairingRequestInsertRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.pairingRequestInsertRequest = aPairingRequestInsertRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(pairingRequestInsertRequest != nil) obj = pairingRequestInsertRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"pairingRequestInsertRequest"];
        [bodyKeys addObject:@"pairingRequestInsertRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "pairingRequestInsertResponse")) {
                                    hr_pairingRequestInsertResponse *bodyObject = [hr_pairingRequestInsertResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftAddDHKeys
@synthesize ftAddDHKeysRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
   ftAddDHKeysRequest:(hr_ftAddDHKeysRequest *)aFtAddDHKeysRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftAddDHKeysRequest = aFtAddDHKeysRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftAddDHKeysRequest != nil) obj = ftAddDHKeysRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftAddDHKeysRequest"];
        [bodyKeys addObject:@"ftAddDHKeysRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftAddDHKeysResponse")) {
                                    hr_ftAddDHKeysResponse *bodyObject = [hr_ftAddDHKeysResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftGetDHKey
@synthesize ftGetDHKeyRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
    ftGetDHKeyRequest:(hr_ftGetDHKeyRequest *)aFtGetDHKeyRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftGetDHKeyRequest = aFtGetDHKeyRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftGetDHKeyRequest != nil) obj = ftGetDHKeyRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftGetDHKeyRequest"];
        [bodyKeys addObject:@"ftGetDHKeyRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftGetDHKeyResponse")) {
                                    hr_ftGetDHKeyResponse *bodyObject = [hr_ftGetDHKeyResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftDeleteFiles
@synthesize ftDeleteFilesRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
 ftDeleteFilesRequest:(hr_ftDeleteFilesRequest *)aFtDeleteFilesRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftDeleteFilesRequest = aFtDeleteFilesRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftDeleteFilesRequest != nil) obj = ftDeleteFilesRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftDeleteFilesRequest"];
        [bodyKeys addObject:@"ftDeleteFilesRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftDeleteFilesResponse")) {
                                    hr_ftDeleteFilesResponse *bodyObject = [hr_ftDeleteFilesResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_whitelist
@synthesize whitelistRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
     whitelistRequest:(hr_whitelistRequest *)aWhitelistRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.whitelistRequest = aWhitelistRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(whitelistRequest != nil) obj = whitelistRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"whitelistRequest"];
        [bodyKeys addObject:@"whitelistRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "whitelistResponse")) {
                                    hr_whitelistResponse *bodyObject = [hr_whitelistResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_whitelistGet
@synthesize whitelistGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
  whitelistGetRequest:(hr_whitelistGetRequest *)aWhitelistGetRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.whitelistGetRequest = aWhitelistGetRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(whitelistGetRequest != nil) obj = whitelistGetRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"whitelistGetRequest"];
        [bodyKeys addObject:@"whitelistGetRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "whitelistGetResponse")) {
                                    hr_whitelistGetResponse *bodyObject = [hr_whitelistGetResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftGetStoredFiles
@synthesize ftGetStoredFilesRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        ftGetStoredFilesRequest:(hr_ftGetStoredFilesRequest *)aFtGetStoredFilesRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftGetStoredFilesRequest = aFtGetStoredFilesRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftGetStoredFilesRequest != nil) obj = ftGetStoredFilesRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftGetStoredFilesRequest"];
        [bodyKeys addObject:@"ftGetStoredFilesRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftGetStoredFilesResponse")) {
                                    hr_ftGetStoredFilesResponse *bodyObject = [hr_ftGetStoredFilesResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_signCertificateV2
@synthesize signCertificateV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        signCertificateV2Request:(hr_signCertificateV2Request *)aSignCertificateV2Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.signCertificateV2Request = aSignCertificateV2Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(signCertificateV2Request != nil) obj = signCertificateV2Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"signCertificateV2Request"];
        [bodyKeys addObject:@"signCertificateV2Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "signCertificateV2Response")) {
                                    hr_signCertificateV2Response *bodyObject = [hr_signCertificateV2Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_general
@synthesize generalRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
       generalRequest:(hr_generalRequest *)aGeneralRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.generalRequest = aGeneralRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(generalRequest != nil) obj = generalRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"generalRequest"];
        [bodyKeys addObject:@"generalRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "generalResponse")) {
                                    hr_generalResponse *bodyObject = [hr_generalResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_getOneTimeToken
@synthesize getOneTimeTokenRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        getOneTimeTokenRequest:(hr_getOneTimeTokenRequest *)aGetOneTimeTokenRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.getOneTimeTokenRequest = aGetOneTimeTokenRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(getOneTimeTokenRequest != nil) obj = getOneTimeTokenRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"getOneTimeTokenRequest"];
        [bodyKeys addObject:@"getOneTimeTokenRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "getOneTimeTokenResponse")) {
                                    hr_getOneTimeTokenResponse *bodyObject = [hr_getOneTimeTokenResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_pushRequest
@synthesize pushRequestRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
   pushRequestRequest:(hr_pushRequestRequest *)aPushRequestRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.pushRequestRequest = aPushRequestRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(pushRequestRequest != nil) obj = pushRequestRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"pushRequestRequest"];
        [bodyKeys addObject:@"pushRequestRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "pushRequestResponse")) {
                                    hr_pushRequestResponse *bodyObject = [hr_pushRequestResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftRemoveDHKeys
@synthesize ftRemoveDHKeysRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
ftRemoveDHKeysRequest:(hr_ftRemoveDHKeysRequest *)aFtRemoveDHKeysRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftRemoveDHKeysRequest = aFtRemoveDHKeysRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftRemoveDHKeysRequest != nil) obj = ftRemoveDHKeysRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftRemoveDHKeysRequest"];
        [bodyKeys addObject:@"ftRemoveDHKeysRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftRemoveDHKeysResponse")) {
                                    hr_ftRemoveDHKeysResponse *bodyObject = [hr_ftRemoveDHKeysResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_clistChangeV2
@synthesize clistChangeV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
 clistChangeV2Request:(hr_clistChangeV2Request *)aClistChangeV2Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.clistChangeV2Request = aClistChangeV2Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(clistChangeV2Request != nil) obj = clistChangeV2Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"clistChangeV2Request"];
        [bodyKeys addObject:@"clistChangeV2Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "clistChangeV2Response")) {
                                    hr_clistChangeV2Response *bodyObject = [hr_clistChangeV2Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_authStateSaveV1
@synthesize authStateSaveV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        authStateSaveV1Request:(hr_authStateSaveV1Request *)aAuthStateSaveV1Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.authStateSaveV1Request = aAuthStateSaveV1Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(authStateSaveV1Request != nil) obj = authStateSaveV1Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"authStateSaveV1Request"];
        [bodyKeys addObject:@"authStateSaveV1Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "authStateSaveV1Response")) {
                                    hr_authStateSaveV1Response *bodyObject = [hr_authStateSaveV1Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_contactlistChange
@synthesize contactlistChangeRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        contactlistChangeRequest:(hr_contactlistChangeRequest *)aContactlistChangeRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.contactlistChangeRequest = aContactlistChangeRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(contactlistChangeRequest != nil) obj = contactlistChangeRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"contactlistChangeRequest"];
        [bodyKeys addObject:@"contactlistChangeRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "contactlistChangeResponse")) {
                                    hr_contactlistChangeResponse *bodyObject = [hr_contactlistChangeResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_signCertificate
@synthesize signCertificateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        signCertificateRequest:(hr_signCertificateRequest *)aSignCertificateRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.signCertificateRequest = aSignCertificateRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(signCertificateRequest != nil) obj = signCertificateRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"signCertificateRequest"];
        [bodyKeys addObject:@"signCertificateRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "signCertificateResponse")) {
                                    hr_signCertificateResponse *bodyObject = [hr_signCertificateResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftGetDHKeyPart2
@synthesize ftGetDHKeyPart2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        ftGetDHKeyPart2Request:(hr_ftGetDHKeyPart2Request *)aFtGetDHKeyPart2Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftGetDHKeyPart2Request = aFtGetDHKeyPart2Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftGetDHKeyPart2Request != nil) obj = ftGetDHKeyPart2Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftGetDHKeyPart2Request"];
        [bodyKeys addObject:@"ftGetDHKeyPart2Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftGetDHKeyPart2Response")) {
                                    hr_ftGetDHKeyPart2Response *bodyObject = [hr_ftGetDHKeyPart2Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_contactlistGet
@synthesize contactlistGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
contactlistGetRequest:(hr_contactlistGetRequest *)aContactlistGetRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.contactlistGetRequest = aContactlistGetRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(contactlistGetRequest != nil) obj = contactlistGetRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"contactlistGetRequest"];
        [bodyKeys addObject:@"contactlistGetRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "contactlistGetResponse")) {
                                    hr_contactlistGetResponse *bodyObject = [hr_contactlistGetResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_pairingRequestFetch
@synthesize pairingRequestFetchRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        pairingRequestFetchRequest:(hr_pairingRequestFetchRequest *)aPairingRequestFetchRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.pairingRequestFetchRequest = aPairingRequestFetchRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(pairingRequestFetchRequest != nil) obj = pairingRequestFetchRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"pairingRequestFetchRequest"];
        [bodyKeys addObject:@"pairingRequestFetchRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "pairingRequestFetchResponse")) {
                                    hr_pairingRequestFetchResponse *bodyObject = [hr_pairingRequestFetchResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_cgroupGet
@synthesize cgroupGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
     cgroupGetRequest:(hr_cgroupGetRequest *)aCgroupGetRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.cgroupGetRequest = aCgroupGetRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(cgroupGetRequest != nil) obj = cgroupGetRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"cgroupGetRequest"];
        [bodyKeys addObject:@"cgroupGetRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "cgroupGetResponse")) {
                                    hr_cgroupGetResponse *bodyObject = [hr_cgroupGetResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_trialEventSave
@synthesize trialEventSaveRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
trialEventSaveRequest:(hr_trialEventSaveRequest *)aTrialEventSaveRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.trialEventSaveRequest = aTrialEventSaveRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(trialEventSaveRequest != nil) obj = trialEventSaveRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"trialEventSaveRequest"];
        [bodyKeys addObject:@"trialEventSaveRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "trialEventSaveResponse")) {
                                    hr_trialEventSaveResponse *bodyObject = [hr_trialEventSaveResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_trialEventGet
@synthesize trialEventGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
 trialEventGetRequest:(hr_trialEventGetRequest *)aTrialEventGetRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.trialEventGetRequest = aTrialEventGetRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(trialEventGetRequest != nil) obj = trialEventGetRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"trialEventGetRequest"];
        [bodyKeys addObject:@"trialEventGetRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "trialEventGetResponse")) {
                                    hr_trialEventGetResponse *bodyObject = [hr_trialEventGetResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_accountSettingsUpdateV1
@synthesize accountSettingsUpdateV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        accountSettingsUpdateV1Request:(hr_accountSettingsUpdateV1Request *)aAccountSettingsUpdateV1Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.accountSettingsUpdateV1Request = aAccountSettingsUpdateV1Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(accountSettingsUpdateV1Request != nil) obj = accountSettingsUpdateV1Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"accountSettingsUpdateV1Request"];
        [bodyKeys addObject:@"accountSettingsUpdateV1Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "accountSettingsUpdateV1Response")) {
                                    hr_accountSettingsUpdateV1Response *bodyObject = [hr_accountSettingsUpdateV1Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_authCheckV3
@synthesize authCheckV3Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
   authCheckV3Request:(hr_authCheckV3Request *)aAuthCheckV3Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.authCheckV3Request = aAuthCheckV3Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(authCheckV3Request != nil) obj = authCheckV3Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"authCheckV3Request"];
        [bodyKeys addObject:@"authCheckV3Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "authCheckV3Response")) {
                                    hr_authCheckV3Response *bodyObject = [hr_authCheckV3Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_clistGetV2
@synthesize clistGetV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
    clistGetV2Request:(hr_clistGetV2Request *)aClistGetV2Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.clistGetV2Request = aClistGetV2Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(clistGetV2Request != nil) obj = clistGetV2Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"clistGetV2Request"];
        [bodyKeys addObject:@"clistGetV2Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "clistGetV2Response")) {
                                    hr_clistGetV2Response *bodyObject = [hr_clistGetV2Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_pushAck
@synthesize pushAckRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
       pushAckRequest:(hr_pushAckRequest *)aPushAckRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.pushAckRequest = aPushAckRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(pushAckRequest != nil) obj = pushAckRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"pushAckRequest"];
        [bodyKeys addObject:@"pushAckRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "pushAckResponse")) {
                                    hr_pushAckResponse *bodyObject = [hr_pushAckResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_accountingSave
@synthesize accountingSaveRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
accountingSaveRequest:(hr_accountingSaveRequest *)aAccountingSaveRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.accountingSaveRequest = aAccountingSaveRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(accountingSaveRequest != nil) obj = accountingSaveRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"accountingSaveRequest"];
        [bodyKeys addObject:@"accountingSaveRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "accountingSaveResponse")) {
                                    hr_accountingSaveResponse *bodyObject = [hr_accountingSaveResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo
@synthesize ftGetStoredDHKeysInfoRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        ftGetStoredDHKeysInfoRequest:(hr_ftGetStoredDHKeysInfoRequest *)aFtGetStoredDHKeysInfoRequest
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.ftGetStoredDHKeysInfoRequest = aFtGetStoredDHKeysInfoRequest;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(ftGetStoredDHKeysInfoRequest != nil) obj = ftGetStoredDHKeysInfoRequest;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"ftGetStoredDHKeysInfoRequest"];
        [bodyKeys addObject:@"ftGetStoredDHKeysInfoRequest"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "ftGetStoredDHKeysInfoResponse")) {
                                    hr_ftGetStoredDHKeysInfoResponse *bodyObject = [hr_ftGetStoredDHKeysInfoResponse deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_accountInfoV1
@synthesize accountInfoV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
 accountInfoV1Request:(hr_accountInfoV1Request *)aAccountInfoV1Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.accountInfoV1Request = aAccountInfoV1Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(accountInfoV1Request != nil) obj = accountInfoV1Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"accountInfoV1Request"];
        [bodyKeys addObject:@"accountInfoV1Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "accountInfoV1Response")) {
                                    hr_accountInfoV1Response *bodyObject = [hr_accountInfoV1Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
@implementation PhoenixPortSoap11Binding_authStateFetchV1
@synthesize authStateFetchV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate
        authStateFetchV1Request:(hr_authStateFetchV1Request *)aAuthStateFetchV1Request
{
    if((self = [super initWithBinding:aBinding delegate:responseDelegate])) {
        self.authStateFetchV1Request = aAuthStateFetchV1Request;
    }

    return self;
}
//- (void)dealloc
//{
//%FOREACH part in operation.input.body.parts
//%IFEQ part.element.type.assignOrRetain retain
//	//if(%«part.name» *** ERROR: undefined key ***  != nil) [%«part.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//%FOREACH header in operation.input.headers
//%IFEQ header.type.assignOrRetain retain
//	//if(%«header.name» *** ERROR: undefined key ***  != nil) [%«header.name» *** ERROR: undefined key ***  release];
//%ENDIF
//%ENDFOR
//
//	[super dealloc];
//}
- (void)main
{
    //[response autorelease];
    response = [PhoenixPortSoap11BindingResponse new];

    PhoenixPortSoap11Binding_envelope *envelope = [PhoenixPortSoap11Binding_envelope sharedInstance];

    NSMutableDictionary *headerElements = nil;
    headerElements = [NSMutableDictionary dictionary];

    NSMutableDictionary *bodyElements = nil;
    NSMutableArray *bodyKeys = nil;
    bodyElements = [NSMutableDictionary dictionary];
    bodyKeys = [NSMutableArray array];
    id obj = nil;
    if(authStateFetchV1Request != nil) obj = authStateFetchV1Request;
    if(obj != nil) {
        [bodyElements setObject:obj forKey:@"authStateFetchV1Request"];
        [bodyKeys addObject:@"authStateFetchV1Request"];
    }

    NSString *operationXMLString = [envelope serializedFormUsingHeaderElements:headerElements bodyElements:bodyElements bodyKeys:bodyKeys];
    operationXMLString = binding.soapSigner ? [binding.soapSigner signRequest:operationXMLString] : operationXMLString;

    [binding sendHTTPCallUsingBody:operationXMLString soapAction:@"" forOperation:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (responseData != nil && delegate != nil)
    {
        xmlDocPtr doc;
        xmlNodePtr cur;

        if (binding.logXMLInOut) {
            DDLogVerbose(@"ResponseBody:\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        }

#if !TARGET_OS_IPHONE && (!defined(MAC_OS_X_VERSION_10_6) || MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_6)
        // Not yet defined in 10.5 libxml
	#define XML_PARSE_COMPACT 0
#endif
        // EricBe: Put explicit conversion since [responseData length] is NSInteger but xmlReadMemory wants int.
        doc = xmlReadMemory([responseData bytes], (int) [responseData length], NULL, NULL, XML_PARSE_COMPACT | XML_PARSE_NOBLANKS);

        if (doc == NULL) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Errors while parsing returned XML" forKey:NSLocalizedDescriptionKey];

            response.error = [NSError errorWithDomain:@"PhoenixPortSoap11BindingResponseXML" code:1 userInfo:userInfo];
            [delegate operation:self completedWithResponse:response];
        } else {
            cur = xmlDocGetRootElement(doc);
            cur = cur->children;

            for( ; cur != NULL ; cur = cur->next) {
                if(cur->type == XML_ELEMENT_NODE) {

                    if(xmlStrEqual(cur->name, (const xmlChar *) "Body")) {
                        NSMutableArray *responseBodyParts = [NSMutableArray array];

                        xmlNodePtr bodyNode;
                        for(bodyNode=cur->children ; bodyNode != NULL ; bodyNode = bodyNode->next) {
                            if(cur->type == XML_ELEMENT_NODE) {
                                if(xmlStrEqual(bodyNode->name, (const xmlChar *) "authStateFetchV1Response")) {
                                    hr_authStateFetchV1Response *bodyObject = [hr_authStateFetchV1Response deserializeNode:bodyNode];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                                if ((bodyNode->ns != nil && xmlStrEqual(bodyNode->ns->prefix, cur->ns->prefix)) &&
                                        xmlStrEqual(bodyNode->name, (const xmlChar *) "Fault")) {
                                    NSDictionary *exceptions = @{
                                    };
                                    SOAPFault *bodyObject = [SOAPFault deserializeNode:bodyNode expectedExceptions:exceptions];
                                    //NSAssert1(bodyObject != nil, @"Errors while parsing body %s", bodyNode->name);
                                    if (bodyObject != nil) [responseBodyParts addObject:bodyObject];
                                }
                            }
                        }

                        response.bodyParts = responseBodyParts;
                    }
                }
            }

            xmlFreeDoc(doc);
        }

        // According to http://xmlsoft.org/html/libxml-parser.html#xmlCleanupParser
        // cleanup should be called only once in the application.
        //xmlCleanupParser();
        [delegate operation:self completedWithResponse:response];
    }
}
@end
static PhoenixPortSoap11Binding_envelope *PhoenixPortSoap11BindingSharedEnvelopeInstance = nil;
@implementation PhoenixPortSoap11Binding_envelope
+ (PhoenixPortSoap11Binding_envelope *)sharedInstance
{
    if(PhoenixPortSoap11BindingSharedEnvelopeInstance == nil) {
        PhoenixPortSoap11BindingSharedEnvelopeInstance = [PhoenixPortSoap11Binding_envelope new];
    }

    return PhoenixPortSoap11BindingSharedEnvelopeInstance;
}
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements bodyKeys:(NSArray *)bodyKeys
{
    xmlDocPtr doc;

    doc = xmlNewDoc((const xmlChar*)XML_DEFAULT_VERSION);
    if (doc == NULL) {
        DDLogError(@"Error creating the xml document tree");
        return @"";
    }

    xmlNodePtr root = xmlNewDocNode(doc, NULL, (const xmlChar*)"Envelope", NULL);
    xmlDocSetRootElement(doc, root);

    xmlNsPtr soapEnvelopeNs = xmlNewNs(root, (const xmlChar*)"http://schemas.xmlsoap.org/soap/envelope/", (const xmlChar*)"soap");
    xmlSetNs(root, soapEnvelopeNs);

    xmlNsPtr xslNs = xmlNewNs(root, (const xmlChar*)"http://www.w3.org/1999/XSL/Transform", (const xmlChar*)"xsl");
    xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema-instance", (const xmlChar*)"xsi");

    xmlNewNsProp(root, xslNs, (const xmlChar*)"version", (const xmlChar*)"1.0");

    xmlNewNs(root, (const xmlChar*)"http://www.w3.org/2001/XMLSchema", (const xmlChar*)"xs");
    xmlNewNs(root, (const xmlChar*)"http://phoenix.com/hr/definitions", (const xmlChar*)"PhoenixPortService");
    xmlNewNs(root, (const xmlChar*)"http://phoenix.com/hr/schemas", (const xmlChar*)"hr");

    if((headerElements != nil) && ([headerElements count] > 0)) {
        xmlNodePtr headerNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Header", NULL);
        xmlAddChild(root, headerNode);

        for(NSString *key in [headerElements allKeys]) {
            id header = [headerElements objectForKey:key];
            xmlAddChild(headerNode, [header xmlNodeForDoc:doc elementName:key elementNSPrefix:nil]);
        }
    }

    if((bodyElements != nil) && ([bodyElements count] > 0)) {
        xmlNodePtr bodyNode = xmlNewDocNode(doc, soapEnvelopeNs, (const xmlChar*)"Body", NULL);
        xmlAddChild(root, bodyNode);

        for(NSString *key in bodyKeys) {
            id body = [bodyElements objectForKey:key];
            xmlAddChild(bodyNode, [body xmlNodeForDoc:doc elementName:key elementNSPrefix:nil]);
        }
    }

    xmlChar *buf;
    int size;
    xmlDocDumpFormatMemory(doc, &buf, &size, 1);

    NSString *serializedForm = [NSString stringWithCString:(const char*)buf encoding:NSUTF8StringEncoding];
    xmlFree(buf);

    xmlFreeDoc(doc);
    return serializedForm;
}
@end
@implementation PhoenixPortSoap11BindingResponse
@synthesize headers;
@synthesize bodyParts;
@synthesize error;
- (id)init
{
    if((self = [super init])) {
        headers = nil;
        bodyParts = nil;
        error = nil;
    }

    return self;
}
//- (void)dealloc {
//	self.headers = nil;
//	self.bodyParts = nil;
//	self.error = nil;
//	[super dealloc];
//}
@end
