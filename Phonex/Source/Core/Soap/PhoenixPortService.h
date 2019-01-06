#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import <libxml/tree.h>
#import "USGlobals.h"
#import <objc/runtime.h>
/* Cookies handling provided by http://en.wikibooks.org/wiki/Programming:WebObjects/Web_Services/Web_Service_Provider */
#import <libxml/parser.h>
#import "xs.h"
#import "PhoenixPortService.h"
#import "hr.h"
@class PhoenixPortSoap11Binding;
@interface PhoenixPortService : NSObject {
	
}
+ (PhoenixPortSoap11Binding *)PhoenixPortSoap11Binding;
@end
@class PhoenixPortSoap11BindingResponse;
@class PhoenixPortSoap11BindingOperation;
@protocol PhoenixPortSoap11BindingResponseDelegate <NSObject>
- (void) operation:(PhoenixPortSoap11BindingOperation *)operation completedWithResponse:(PhoenixPortSoap11BindingResponse *)response;
@end
#define kServerAnchorCertificates   @"kServerAnchorCertificates"
#define kServerAnchorsOnly          @"kServerAnchorsOnly"
#define kClientIdentity             @"kClientIdentity"
#define kClientCertificates         @"kClientCertificates"
#define kClientUsername             @"kClientUsername"
#define kClientPassword             @"kClientPassword"
#define kNSURLCredentialPersistence @"kNSURLCredentialPersistence"
#define kValidateResult             @"kValidateResult"
@interface PhoenixPortSoap11Binding : NSObject <PhoenixPortSoap11BindingResponseDelegate> {
	NSURL *address;
	NSTimeInterval timeout;
	NSMutableArray *cookies;
	NSMutableDictionary *customHeaders;
	BOOL logXMLInOut;
	BOOL ignoreEmptyResponse;
	BOOL synchronousOperationComplete;
	id<SSLCredentialsManaging> sslManager;
	SOAPSigner *soapSigner;
}
@property (nonatomic, copy) NSURL *address;
@property (nonatomic) BOOL logXMLInOut;
@property (nonatomic) BOOL ignoreEmptyResponse;
@property (nonatomic) NSTimeInterval timeout;
@property (nonatomic, retain) NSMutableArray *cookies;
@property (nonatomic, retain) NSMutableDictionary *customHeaders;
@property (nonatomic, retain) id<SSLCredentialsManaging> sslManager;
@property (nonatomic, retain) SOAPSigner *soapSigner;
+ (NSTimeInterval) defaultTimeout;
- (id)initWithAddress:(NSString *)anAddress;
- (void)sendHTTPCallUsingBody:(NSString *)body soapAction:(NSString *)soapAction forOperation:(PhoenixPortSoap11BindingOperation *)operation;
- (void)addCookie:(NSHTTPCookie *)toAdd;
- (NSString *)MIMEType;
- (PhoenixPortSoap11BindingResponse *)accountingFetchUsingAccountingFetchRequest:(hr_accountingFetchRequest *)aAccountingFetchRequest ;
- (void)accountingFetchAsyncUsingAccountingFetchRequest:(hr_accountingFetchRequest *)aAccountingFetchRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)cgroupUpdateUsingCgroupUpdateRequest:(hr_cgroupUpdateRequest *)aCgroupUpdateRequest ;
- (void)cgroupUpdateAsyncUsingCgroupUpdateRequest:(hr_cgroupUpdateRequest *)aCgroupUpdateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)pairingRequestUpdateUsingPairingRequestUpdateRequest:(hr_pairingRequestUpdateRequest *)aPairingRequestUpdateRequest ;
- (void)pairingRequestUpdateAsyncUsingPairingRequestUpdateRequest:(hr_pairingRequestUpdateRequest *)aPairingRequestUpdateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)passwordChangeV2UsingPasswordChangeV2Request:(hr_passwordChangeV2Request *)aPasswordChangeV2Request ;
- (void)passwordChangeV2AsyncUsingPasswordChangeV2Request:(hr_passwordChangeV2Request *)aPasswordChangeV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)getCertificateUsingGetCertificateRequest:(hr_getCertificateRequest *)aGetCertificateRequest ;
- (void)getCertificateAsyncUsingGetCertificateRequest:(hr_getCertificateRequest *)aGetCertificateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)pairingRequestInsertUsingPairingRequestInsertRequest:(hr_pairingRequestInsertRequest *)aPairingRequestInsertRequest ;
- (void)pairingRequestInsertAsyncUsingPairingRequestInsertRequest:(hr_pairingRequestInsertRequest *)aPairingRequestInsertRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftAddDHKeysUsingFtAddDHKeysRequest:(hr_ftAddDHKeysRequest *)aFtAddDHKeysRequest ;
- (void)ftAddDHKeysAsyncUsingFtAddDHKeysRequest:(hr_ftAddDHKeysRequest *)aFtAddDHKeysRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftGetDHKeyUsingFtGetDHKeyRequest:(hr_ftGetDHKeyRequest *)aFtGetDHKeyRequest ;
- (void)ftGetDHKeyAsyncUsingFtGetDHKeyRequest:(hr_ftGetDHKeyRequest *)aFtGetDHKeyRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftDeleteFilesUsingFtDeleteFilesRequest:(hr_ftDeleteFilesRequest *)aFtDeleteFilesRequest ;
- (void)ftDeleteFilesAsyncUsingFtDeleteFilesRequest:(hr_ftDeleteFilesRequest *)aFtDeleteFilesRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)whitelistUsingWhitelistRequest:(hr_whitelistRequest *)aWhitelistRequest ;
- (void)whitelistAsyncUsingWhitelistRequest:(hr_whitelistRequest *)aWhitelistRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)whitelistGetUsingWhitelistGetRequest:(hr_whitelistGetRequest *)aWhitelistGetRequest ;
- (void)whitelistGetAsyncUsingWhitelistGetRequest:(hr_whitelistGetRequest *)aWhitelistGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftGetStoredFilesUsingFtGetStoredFilesRequest:(hr_ftGetStoredFilesRequest *)aFtGetStoredFilesRequest ;
- (void)ftGetStoredFilesAsyncUsingFtGetStoredFilesRequest:(hr_ftGetStoredFilesRequest *)aFtGetStoredFilesRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)signCertificateV2UsingSignCertificateV2Request:(hr_signCertificateV2Request *)aSignCertificateV2Request ;
- (void)signCertificateV2AsyncUsingSignCertificateV2Request:(hr_signCertificateV2Request *)aSignCertificateV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)generalUsingGeneralRequest:(hr_generalRequest *)aGeneralRequest ;
- (void)generalAsyncUsingGeneralRequest:(hr_generalRequest *)aGeneralRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)getOneTimeTokenUsingGetOneTimeTokenRequest:(hr_getOneTimeTokenRequest *)aGetOneTimeTokenRequest ;
- (void)getOneTimeTokenAsyncUsingGetOneTimeTokenRequest:(hr_getOneTimeTokenRequest *)aGetOneTimeTokenRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)pushRequestUsingPushRequestRequest:(hr_pushRequestRequest *)aPushRequestRequest ;
- (void)pushRequestAsyncUsingPushRequestRequest:(hr_pushRequestRequest *)aPushRequestRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftRemoveDHKeysUsingFtRemoveDHKeysRequest:(hr_ftRemoveDHKeysRequest *)aFtRemoveDHKeysRequest ;
- (void)ftRemoveDHKeysAsyncUsingFtRemoveDHKeysRequest:(hr_ftRemoveDHKeysRequest *)aFtRemoveDHKeysRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)clistChangeV2UsingClistChangeV2Request:(hr_clistChangeV2Request *)aClistChangeV2Request ;
- (void)clistChangeV2AsyncUsingClistChangeV2Request:(hr_clistChangeV2Request *)aClistChangeV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)authStateSaveV1UsingAuthStateSaveV1Request:(hr_authStateSaveV1Request *)aAuthStateSaveV1Request ;
- (void)authStateSaveV1AsyncUsingAuthStateSaveV1Request:(hr_authStateSaveV1Request *)aAuthStateSaveV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)contactlistChangeUsingContactlistChangeRequest:(hr_contactlistChangeRequest *)aContactlistChangeRequest ;
- (void)contactlistChangeAsyncUsingContactlistChangeRequest:(hr_contactlistChangeRequest *)aContactlistChangeRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)signCertificateUsingSignCertificateRequest:(hr_signCertificateRequest *)aSignCertificateRequest ;
- (void)signCertificateAsyncUsingSignCertificateRequest:(hr_signCertificateRequest *)aSignCertificateRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftGetDHKeyPart2UsingFtGetDHKeyPart2Request:(hr_ftGetDHKeyPart2Request *)aFtGetDHKeyPart2Request ;
- (void)ftGetDHKeyPart2AsyncUsingFtGetDHKeyPart2Request:(hr_ftGetDHKeyPart2Request *)aFtGetDHKeyPart2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)contactlistGetUsingContactlistGetRequest:(hr_contactlistGetRequest *)aContactlistGetRequest ;
- (void)contactlistGetAsyncUsingContactlistGetRequest:(hr_contactlistGetRequest *)aContactlistGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)pairingRequestFetchUsingPairingRequestFetchRequest:(hr_pairingRequestFetchRequest *)aPairingRequestFetchRequest ;
- (void)pairingRequestFetchAsyncUsingPairingRequestFetchRequest:(hr_pairingRequestFetchRequest *)aPairingRequestFetchRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)cgroupGetUsingCgroupGetRequest:(hr_cgroupGetRequest *)aCgroupGetRequest ;
- (void)cgroupGetAsyncUsingCgroupGetRequest:(hr_cgroupGetRequest *)aCgroupGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)trialEventSaveUsingTrialEventSaveRequest:(hr_trialEventSaveRequest *)aTrialEventSaveRequest ;
- (void)trialEventSaveAsyncUsingTrialEventSaveRequest:(hr_trialEventSaveRequest *)aTrialEventSaveRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)trialEventGetUsingTrialEventGetRequest:(hr_trialEventGetRequest *)aTrialEventGetRequest ;
- (void)trialEventGetAsyncUsingTrialEventGetRequest:(hr_trialEventGetRequest *)aTrialEventGetRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)accountSettingsUpdateV1UsingAccountSettingsUpdateV1Request:(hr_accountSettingsUpdateV1Request *)aAccountSettingsUpdateV1Request ;
- (void)accountSettingsUpdateV1AsyncUsingAccountSettingsUpdateV1Request:(hr_accountSettingsUpdateV1Request *)aAccountSettingsUpdateV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)authCheckV3UsingAuthCheckV3Request:(hr_authCheckV3Request *)aAuthCheckV3Request ;
- (void)authCheckV3AsyncUsingAuthCheckV3Request:(hr_authCheckV3Request *)aAuthCheckV3Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)clistGetV2UsingClistGetV2Request:(hr_clistGetV2Request *)aClistGetV2Request ;
- (void)clistGetV2AsyncUsingClistGetV2Request:(hr_clistGetV2Request *)aClistGetV2Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)pushAckUsingPushAckRequest:(hr_pushAckRequest *)aPushAckRequest ;
- (void)pushAckAsyncUsingPushAckRequest:(hr_pushAckRequest *)aPushAckRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)accountingSaveUsingAccountingSaveRequest:(hr_accountingSaveRequest *)aAccountingSaveRequest ;
- (void)accountingSaveAsyncUsingAccountingSaveRequest:(hr_accountingSaveRequest *)aAccountingSaveRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)ftGetStoredDHKeysInfoUsingFtGetStoredDHKeysInfoRequest:(hr_ftGetStoredDHKeysInfoRequest *)aFtGetStoredDHKeysInfoRequest ;
- (void)ftGetStoredDHKeysInfoAsyncUsingFtGetStoredDHKeysInfoRequest:(hr_ftGetStoredDHKeysInfoRequest *)aFtGetStoredDHKeysInfoRequest  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)accountInfoV1UsingAccountInfoV1Request:(hr_accountInfoV1Request *)aAccountInfoV1Request ;
- (void)accountInfoV1AsyncUsingAccountInfoV1Request:(hr_accountInfoV1Request *)aAccountInfoV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
- (PhoenixPortSoap11BindingResponse *)authStateFetchV1UsingAuthStateFetchV1Request:(hr_authStateFetchV1Request *)aAuthStateFetchV1Request ;
- (void)authStateFetchV1AsyncUsingAuthStateFetchV1Request:(hr_authStateFetchV1Request *)aAuthStateFetchV1Request  delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)responseDelegate;
@end
@interface PhoenixPortSoap11BindingOperation : NSOperation {
	PhoenixPortSoap11Binding *binding;
	PhoenixPortSoap11BindingResponse *response;
	__weak id<PhoenixPortSoap11BindingResponseDelegate> delegate;
	NSMutableData *responseData;
	NSURLConnection *urlConnection;
}
@property (nonatomic, retain) PhoenixPortSoap11Binding *binding;
@property (nonatomic, readonly) PhoenixPortSoap11BindingResponse *response;
@property (nonatomic, weak) id<PhoenixPortSoap11BindingResponseDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSURLConnection *urlConnection;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
@end
@interface PhoenixPortSoap11Binding_accountingFetch : PhoenixPortSoap11BindingOperation {
	hr_accountingFetchRequest * accountingFetchRequest;
}
@property (nonatomic, retain) hr_accountingFetchRequest * accountingFetchRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	accountingFetchRequest:(hr_accountingFetchRequest *)aAccountingFetchRequest
;
@end
@interface PhoenixPortSoap11Binding_cgroupUpdate : PhoenixPortSoap11BindingOperation {
	hr_cgroupUpdateRequest * cgroupUpdateRequest;
}
@property (nonatomic, retain) hr_cgroupUpdateRequest * cgroupUpdateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	cgroupUpdateRequest:(hr_cgroupUpdateRequest *)aCgroupUpdateRequest
;
@end
@interface PhoenixPortSoap11Binding_pairingRequestUpdate : PhoenixPortSoap11BindingOperation {
	hr_pairingRequestUpdateRequest * pairingRequestUpdateRequest;
}
@property (nonatomic, retain) hr_pairingRequestUpdateRequest * pairingRequestUpdateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	pairingRequestUpdateRequest:(hr_pairingRequestUpdateRequest *)aPairingRequestUpdateRequest
;
@end
@interface PhoenixPortSoap11Binding_passwordChangeV2 : PhoenixPortSoap11BindingOperation {
	hr_passwordChangeV2Request * passwordChangeV2Request;
}
@property (nonatomic, retain) hr_passwordChangeV2Request * passwordChangeV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	passwordChangeV2Request:(hr_passwordChangeV2Request *)aPasswordChangeV2Request
;
@end
@interface PhoenixPortSoap11Binding_getCertificate : PhoenixPortSoap11BindingOperation {
	hr_getCertificateRequest * getCertificateRequest;
}
@property (nonatomic, retain) hr_getCertificateRequest * getCertificateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	getCertificateRequest:(hr_getCertificateRequest *)aGetCertificateRequest
;
@end
@interface PhoenixPortSoap11Binding_pairingRequestInsert : PhoenixPortSoap11BindingOperation {
	hr_pairingRequestInsertRequest * pairingRequestInsertRequest;
}
@property (nonatomic, retain) hr_pairingRequestInsertRequest * pairingRequestInsertRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	pairingRequestInsertRequest:(hr_pairingRequestInsertRequest *)aPairingRequestInsertRequest
;
@end
@interface PhoenixPortSoap11Binding_ftAddDHKeys : PhoenixPortSoap11BindingOperation {
	hr_ftAddDHKeysRequest * ftAddDHKeysRequest;
}
@property (nonatomic, retain) hr_ftAddDHKeysRequest * ftAddDHKeysRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftAddDHKeysRequest:(hr_ftAddDHKeysRequest *)aFtAddDHKeysRequest
;
@end
@interface PhoenixPortSoap11Binding_ftGetDHKey : PhoenixPortSoap11BindingOperation {
	hr_ftGetDHKeyRequest * ftGetDHKeyRequest;
}
@property (nonatomic, retain) hr_ftGetDHKeyRequest * ftGetDHKeyRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftGetDHKeyRequest:(hr_ftGetDHKeyRequest *)aFtGetDHKeyRequest
;
@end
@interface PhoenixPortSoap11Binding_ftDeleteFiles : PhoenixPortSoap11BindingOperation {
	hr_ftDeleteFilesRequest * ftDeleteFilesRequest;
}
@property (nonatomic, retain) hr_ftDeleteFilesRequest * ftDeleteFilesRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftDeleteFilesRequest:(hr_ftDeleteFilesRequest *)aFtDeleteFilesRequest
;
@end
@interface PhoenixPortSoap11Binding_whitelist : PhoenixPortSoap11BindingOperation {
	hr_whitelistRequest * whitelistRequest;
}
@property (nonatomic, retain) hr_whitelistRequest * whitelistRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	whitelistRequest:(hr_whitelistRequest *)aWhitelistRequest
;
@end
@interface PhoenixPortSoap11Binding_whitelistGet : PhoenixPortSoap11BindingOperation {
	hr_whitelistGetRequest * whitelistGetRequest;
}
@property (nonatomic, retain) hr_whitelistGetRequest * whitelistGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	whitelistGetRequest:(hr_whitelistGetRequest *)aWhitelistGetRequest
;
@end
@interface PhoenixPortSoap11Binding_ftGetStoredFiles : PhoenixPortSoap11BindingOperation {
	hr_ftGetStoredFilesRequest * ftGetStoredFilesRequest;
}
@property (nonatomic, retain) hr_ftGetStoredFilesRequest * ftGetStoredFilesRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftGetStoredFilesRequest:(hr_ftGetStoredFilesRequest *)aFtGetStoredFilesRequest
;
@end
@interface PhoenixPortSoap11Binding_signCertificateV2 : PhoenixPortSoap11BindingOperation {
	hr_signCertificateV2Request * signCertificateV2Request;
}
@property (nonatomic, retain) hr_signCertificateV2Request * signCertificateV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	signCertificateV2Request:(hr_signCertificateV2Request *)aSignCertificateV2Request
;
@end
@interface PhoenixPortSoap11Binding_general : PhoenixPortSoap11BindingOperation {
	hr_generalRequest * generalRequest;
}
@property (nonatomic, retain) hr_generalRequest * generalRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	generalRequest:(hr_generalRequest *)aGeneralRequest
;
@end
@interface PhoenixPortSoap11Binding_getOneTimeToken : PhoenixPortSoap11BindingOperation {
	hr_getOneTimeTokenRequest * getOneTimeTokenRequest;
}
@property (nonatomic, retain) hr_getOneTimeTokenRequest * getOneTimeTokenRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	getOneTimeTokenRequest:(hr_getOneTimeTokenRequest *)aGetOneTimeTokenRequest
;
@end
@interface PhoenixPortSoap11Binding_pushRequest : PhoenixPortSoap11BindingOperation {
	hr_pushRequestRequest * pushRequestRequest;
}
@property (nonatomic, retain) hr_pushRequestRequest * pushRequestRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	pushRequestRequest:(hr_pushRequestRequest *)aPushRequestRequest
;
@end
@interface PhoenixPortSoap11Binding_ftRemoveDHKeys : PhoenixPortSoap11BindingOperation {
	hr_ftRemoveDHKeysRequest * ftRemoveDHKeysRequest;
}
@property (nonatomic, retain) hr_ftRemoveDHKeysRequest * ftRemoveDHKeysRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftRemoveDHKeysRequest:(hr_ftRemoveDHKeysRequest *)aFtRemoveDHKeysRequest
;
@end
@interface PhoenixPortSoap11Binding_clistChangeV2 : PhoenixPortSoap11BindingOperation {
	hr_clistChangeV2Request * clistChangeV2Request;
}
@property (nonatomic, retain) hr_clistChangeV2Request * clistChangeV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	clistChangeV2Request:(hr_clistChangeV2Request *)aClistChangeV2Request
;
@end
@interface PhoenixPortSoap11Binding_authStateSaveV1 : PhoenixPortSoap11BindingOperation {
	hr_authStateSaveV1Request * authStateSaveV1Request;
}
@property (nonatomic, retain) hr_authStateSaveV1Request * authStateSaveV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	authStateSaveV1Request:(hr_authStateSaveV1Request *)aAuthStateSaveV1Request
;
@end
@interface PhoenixPortSoap11Binding_contactlistChange : PhoenixPortSoap11BindingOperation {
	hr_contactlistChangeRequest * contactlistChangeRequest;
}
@property (nonatomic, retain) hr_contactlistChangeRequest * contactlistChangeRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	contactlistChangeRequest:(hr_contactlistChangeRequest *)aContactlistChangeRequest
;
@end
@interface PhoenixPortSoap11Binding_signCertificate : PhoenixPortSoap11BindingOperation {
	hr_signCertificateRequest * signCertificateRequest;
}
@property (nonatomic, retain) hr_signCertificateRequest * signCertificateRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	signCertificateRequest:(hr_signCertificateRequest *)aSignCertificateRequest
;
@end
@interface PhoenixPortSoap11Binding_ftGetDHKeyPart2 : PhoenixPortSoap11BindingOperation {
	hr_ftGetDHKeyPart2Request * ftGetDHKeyPart2Request;
}
@property (nonatomic, retain) hr_ftGetDHKeyPart2Request * ftGetDHKeyPart2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftGetDHKeyPart2Request:(hr_ftGetDHKeyPart2Request *)aFtGetDHKeyPart2Request
;
@end
@interface PhoenixPortSoap11Binding_contactlistGet : PhoenixPortSoap11BindingOperation {
	hr_contactlistGetRequest * contactlistGetRequest;
}
@property (nonatomic, retain) hr_contactlistGetRequest * contactlistGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	contactlistGetRequest:(hr_contactlistGetRequest *)aContactlistGetRequest
;
@end
@interface PhoenixPortSoap11Binding_pairingRequestFetch : PhoenixPortSoap11BindingOperation {
	hr_pairingRequestFetchRequest * pairingRequestFetchRequest;
}
@property (nonatomic, retain) hr_pairingRequestFetchRequest * pairingRequestFetchRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	pairingRequestFetchRequest:(hr_pairingRequestFetchRequest *)aPairingRequestFetchRequest
;
@end
@interface PhoenixPortSoap11Binding_cgroupGet : PhoenixPortSoap11BindingOperation {
	hr_cgroupGetRequest * cgroupGetRequest;
}
@property (nonatomic, retain) hr_cgroupGetRequest * cgroupGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	cgroupGetRequest:(hr_cgroupGetRequest *)aCgroupGetRequest
;
@end
@interface PhoenixPortSoap11Binding_trialEventSave : PhoenixPortSoap11BindingOperation {
	hr_trialEventSaveRequest * trialEventSaveRequest;
}
@property (nonatomic, retain) hr_trialEventSaveRequest * trialEventSaveRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	trialEventSaveRequest:(hr_trialEventSaveRequest *)aTrialEventSaveRequest
;
@end
@interface PhoenixPortSoap11Binding_trialEventGet : PhoenixPortSoap11BindingOperation {
	hr_trialEventGetRequest * trialEventGetRequest;
}
@property (nonatomic, retain) hr_trialEventGetRequest * trialEventGetRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	trialEventGetRequest:(hr_trialEventGetRequest *)aTrialEventGetRequest
;
@end
@interface PhoenixPortSoap11Binding_accountSettingsUpdateV1 : PhoenixPortSoap11BindingOperation {
	hr_accountSettingsUpdateV1Request * accountSettingsUpdateV1Request;
}
@property (nonatomic, retain) hr_accountSettingsUpdateV1Request * accountSettingsUpdateV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	accountSettingsUpdateV1Request:(hr_accountSettingsUpdateV1Request *)aAccountSettingsUpdateV1Request
;
@end
@interface PhoenixPortSoap11Binding_authCheckV3 : PhoenixPortSoap11BindingOperation {
	hr_authCheckV3Request * authCheckV3Request;
}
@property (nonatomic, retain) hr_authCheckV3Request * authCheckV3Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	authCheckV3Request:(hr_authCheckV3Request *)aAuthCheckV3Request
;
@end
@interface PhoenixPortSoap11Binding_clistGetV2 : PhoenixPortSoap11BindingOperation {
	hr_clistGetV2Request * clistGetV2Request;
}
@property (nonatomic, retain) hr_clistGetV2Request * clistGetV2Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	clistGetV2Request:(hr_clistGetV2Request *)aClistGetV2Request
;
@end
@interface PhoenixPortSoap11Binding_pushAck : PhoenixPortSoap11BindingOperation {
	hr_pushAckRequest * pushAckRequest;
}
@property (nonatomic, retain) hr_pushAckRequest * pushAckRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	pushAckRequest:(hr_pushAckRequest *)aPushAckRequest
;
@end
@interface PhoenixPortSoap11Binding_accountingSave : PhoenixPortSoap11BindingOperation {
	hr_accountingSaveRequest * accountingSaveRequest;
}
@property (nonatomic, retain) hr_accountingSaveRequest * accountingSaveRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	accountingSaveRequest:(hr_accountingSaveRequest *)aAccountingSaveRequest
;
@end
@interface PhoenixPortSoap11Binding_ftGetStoredDHKeysInfo : PhoenixPortSoap11BindingOperation {
	hr_ftGetStoredDHKeysInfoRequest * ftGetStoredDHKeysInfoRequest;
}
@property (nonatomic, retain) hr_ftGetStoredDHKeysInfoRequest * ftGetStoredDHKeysInfoRequest;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	ftGetStoredDHKeysInfoRequest:(hr_ftGetStoredDHKeysInfoRequest *)aFtGetStoredDHKeysInfoRequest
;
@end
@interface PhoenixPortSoap11Binding_accountInfoV1 : PhoenixPortSoap11BindingOperation {
	hr_accountInfoV1Request * accountInfoV1Request;
}
@property (nonatomic, retain) hr_accountInfoV1Request * accountInfoV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	accountInfoV1Request:(hr_accountInfoV1Request *)aAccountInfoV1Request
;
@end
@interface PhoenixPortSoap11Binding_authStateFetchV1 : PhoenixPortSoap11BindingOperation {
	hr_authStateFetchV1Request * authStateFetchV1Request;
}
@property (nonatomic, retain) hr_authStateFetchV1Request * authStateFetchV1Request;
- (id)initWithBinding:(PhoenixPortSoap11Binding *)aBinding delegate:(id<PhoenixPortSoap11BindingResponseDelegate>)aDelegate
	authStateFetchV1Request:(hr_authStateFetchV1Request *)aAuthStateFetchV1Request
;
@end
@interface PhoenixPortSoap11Binding_envelope : NSObject {
}
+ (PhoenixPortSoap11Binding_envelope *)sharedInstance;
- (NSString *)serializedFormUsingHeaderElements:(NSDictionary *)headerElements bodyElements:(NSDictionary *)bodyElements bodyKeys:(NSArray *)bodyKeys;
@end
@interface PhoenixPortSoap11BindingResponse : NSObject {
	NSArray *headers;
	NSArray *bodyParts;
	NSError *error;
}
@property (nonatomic, retain) NSArray *headers;
@property (nonatomic, retain) NSArray *bodyParts;
@property (nonatomic, retain) NSError *error;
@end
