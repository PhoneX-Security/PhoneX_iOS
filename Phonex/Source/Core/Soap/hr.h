#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import <libxml/tree.h>
#import "USGlobals.h"
#import <objc/runtime.h>
@class hr_accountInfoV1Request;
@class NSString;
@class hr_accountInfoV1Response;
@class hr_accountSettingsUpdateV1Request;
@class hr_accountSettingsUpdateV1Response;
@class hr_generalRequest;
@class hr_generalResponse;
@class NSString;
@class NSNumber;
@class NSString;
@class hr_groupRecord;
@class NSNumber;
@class NSData;
@class hr_aliasList;
@class hr_sipList;
@class hr_userIdentifier;
@class hr_groupIdentifier;
@class hr_getOneTimeTokenRequest;
@class hr_getOneTimeTokenResponse;
@class hr_passwordChangeV2Request;
@class hr_passwordChangeV2Response;
@class hr_authCheckV3Request;
@class hr_authCheckV3Response;
@class hr_getCertificateRequest;
@class hr_certificateRequestElement;
@class hr_certificateWrapper;
@class hr_getCertificateResponse;
@class hr_signCertificateRequest;
@class hr_signCertificateResponse;
@class hr_signCertificateV2Request;
@class hr_signCertificateV2Response;
@class hr_contactlistReturn;
@class hr_contactlistChangeRequestElement;
@class hr_contactListElement;
@class hr_whitelistRequestElement;
@class hr_whitelistElement;
@class NSNumber;
@class hr_whitelistRequest;
@class hr_whitelistResponse;
@class hr_whitelistGetRequest;
@class hr_whitelistGetResponse;
@class hr_contactlistGetRequest;
@class hr_contactlistGetResponse;
@class hr_contactlistChangeRequest;
@class hr_contactlistChangeResponse;
@class hr_clistElementV2;
@class hr_clistElementListV2;
@class hr_clistGetV2Request;
@class hr_clistGetV2Response;
@class hr_clistChangeRequestElementV2;
@class hr_clistChangeListV2;
@class hr_clistChangeResultV2;
@class hr_clistChangeV2Request;
@class hr_clistChangeResultListV2;
@class hr_clistChangeV2Response;
@class hr_cgroup;
@class hr_cgroupList;
@class hr_cgroupIdList;
@class hr_cgroupGetRequest;
@class hr_cgroupGetResponse;
@class hr_cgroupUpdateRequestElement;
@class hr_cgroupUpdateRequestList;
@class hr_cgroupUpdateResult;
@class hr_cgroupUpdateResultList;
@class hr_cgroupUpdateRequest;
@class hr_cgroupUpdateResponse;
@class NSString;
@class NSString;
@class hr_ftDHKey;
@class hr_sipDatePair;
@class hr_sipDatePairList;
@class hr_ftAddDHKeysRequest;
@class NSNumber;
@class hr_ftAddDHKeysReturnList;
@class hr_ftAddDHKeysResponse;
@class hr_ftRemoveDHKeysRequest;
@class hr_ftNonceList;
@class hr_ftRemoveDHKeysResponse;
@class hr_ftDHKeyUserInfo;
@class hr_ftDHKeyUserStats;
@class hr_ftDHKeyUserInfoArr;
@class hr_ftDHKeyUserStatsArr;
@class hr_ftGetStoredDHKeysInfoRequest;
@class hr_ftGetStoredDHKeysInfoResponse;
@class hr_ftGetDHKeyRequest;
@class hr_ftGetDHKeyResponse;
@class hr_ftGetDHKeyPart2Request;
@class hr_ftGetDHKeyPart2Response;
@class hr_ftDeleteFilesRequest;
@class hr_ftDeleteFilesResponse;
@class hr_ftStoredFile;
@class hr_ftStoredFileList;
@class hr_ftGetStoredFilesRequest;
@class hr_ftGetStoredFilesResponse;
@class hr_pairingRequestFetchRequest;
@class hr_pairingRequestElement;
@class hr_pairingRequestList;
@class hr_pairingRequestFetchResponse;
@class hr_pairingRequestInsertRequest;
@class hr_pairingRequestInsertResponse;
@class hr_pairingRequestUpdateElement;
@class hr_pairingRequestUpdateList;
@class hr_pairingRequestUpdateResultList;
@class hr_pairingRequestUpdateRequest;
@class hr_pairingRequestUpdateResponse;
@class hr_trialEventSaveRequest;
@class hr_trialEventSaveResponse;
@class hr_trialEventGetRequest;
@class hr_trialEventGetResponse;
@class hr_pushRequestRequest;
@class hr_pushRequestResponse;
@class hr_pushAckRequest;
@class hr_pushAckResponse;
@class hr_authStateSaveV1Request;
@class hr_authStateSaveV1Response;
@class hr_authStateFetchV1Request;
@class hr_authStateFetchV1Response;
@class hr_accountingSaveRequest;
@class hr_accountingSaveResponse;
@class hr_accountingFetchRequest;
@class hr_accountingFetchResponse;
@interface hr_accountInfoV1Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountInfoV1Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_trueFalse_none = 0,
	hr_trueFalse_true,
	hr_trueFalse_false,
} hr_trueFalse;
hr_trueFalse hr_trueFalse_enumFromString(NSString *string);
NSString * hr_trueFalse_stringFromEnum(hr_trueFalse enumValue);
@interface hr_accountInfoV1Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_trueFalse forcePasswordChange;
	NSNumber * storedFilesNum;
	NSDate * serverTime;
	NSString * licenseType;
	NSDate * accountIssued;
	NSDate * accountExpires;
	NSDate * firstAuthCheckDate;
	NSDate * lastAuthCheckDate;
	NSDate * firstLoginDate;
	NSDate * firstUserAddDate;
	NSDate * accountLastActivity;
	NSDate * accountLastPassChange;
	USBoolean * accountDisabled;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountInfoV1Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, assign) hr_trueFalse forcePasswordChange;
@property (nonatomic, retain) NSNumber * storedFilesNum;
@property (nonatomic, retain) NSDate * serverTime;
@property (nonatomic, retain) NSString * licenseType;
@property (nonatomic, retain) NSDate * accountIssued;
@property (nonatomic, retain) NSDate * accountExpires;
@property (nonatomic, retain) NSDate * firstAuthCheckDate;
@property (nonatomic, retain) NSDate * lastAuthCheckDate;
@property (nonatomic, retain) NSDate * firstLoginDate;
@property (nonatomic, retain) NSDate * firstUserAddDate;
@property (nonatomic, retain) NSDate * accountLastActivity;
@property (nonatomic, retain) NSDate * accountLastPassChange;
@property (nonatomic, retain) USBoolean * accountDisabled;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_accountSettingsUpdateV1Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSString * requestBody;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountSettingsUpdateV1Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSString * requestBody;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_accountSettingsUpdateV1Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * errText;
	NSString * responseBody;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountSettingsUpdateV1Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * errText;
@property (nonatomic, retain) NSString * responseBody;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_generalRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * reqType;
	NSString * reqJSON;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_generalRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * reqType;
@property (nonatomic, retain) NSString * reqJSON;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_generalResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * errText;
	NSString * responseJSON;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_generalResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * errText;
@property (nonatomic, retain) NSString * responseJSON;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_groupRecord : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * groupId;
	NSString * groupName;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_groupRecord *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * groupId;
@property (nonatomic, retain) NSString * groupName;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_enabledDisabled_none = 0,
	hr_enabledDisabled_enabled,
	hr_enabledDisabled_disabled,
} hr_enabledDisabled;
hr_enabledDisabled hr_enabledDisabled_enumFromString(NSString *string);
NSString * hr_enabledDisabled_stringFromEnum(hr_enabledDisabled enumValue);
typedef enum {
	hr_trueFalseNA_none = 0,
	hr_trueFalseNA_true,
	hr_trueFalseNA_false,
	hr_trueFalseNA_na,
} hr_trueFalseNA;
hr_trueFalseNA hr_trueFalseNA_enumFromString(NSString *string);
NSString * hr_trueFalseNA_stringFromEnum(hr_trueFalseNA enumValue);
typedef enum {
	hr_userPresenceStatus_none = 0,
	hr_userPresenceStatus_online,
	hr_userPresenceStatus_offline,
	hr_userPresenceStatus_away,
	hr_userPresenceStatus_dnd,
	hr_userPresenceStatus_invisible,
} hr_userPresenceStatus;
hr_userPresenceStatus hr_userPresenceStatus_enumFromString(NSString *string);
NSString * hr_userPresenceStatus_stringFromEnum(hr_userPresenceStatus enumValue);
typedef enum {
	hr_userWhitelistStatus_none = 0,
	hr_userWhitelistStatus_in,
	hr_userWhitelistStatus_notin,
	hr_userWhitelistStatus_disabled,
	hr_userWhitelistStatus_noclue,
} hr_userWhitelistStatus;
hr_userWhitelistStatus hr_userWhitelistStatus_enumFromString(NSString *string);
NSString * hr_userWhitelistStatus_stringFromEnum(hr_userWhitelistStatus enumValue);
@interface hr_aliasList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *alias;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_aliasList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addAlias:(NSString *)toAdd;
@property (nonatomic, readonly) NSMutableArray * alias;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_sipList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *user;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_sipList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addUser:(NSString *)toAdd;
@property (nonatomic, readonly) NSMutableArray * user;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_userIdentifier : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * userSIP;
	NSNumber * userID;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_userIdentifier *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * userSIP;
@property (nonatomic, retain) NSNumber * userID;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_groupIdentifier : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * groupID;
	NSString * groupName;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_groupIdentifier *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * groupID;
@property (nonatomic, retain) NSString * groupName;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_certificateStatus_none = 0,
	hr_certificateStatus_ok,
	hr_certificateStatus_invalid,
	hr_certificateStatus_revoked,
	hr_certificateStatus_forbidden,
	hr_certificateStatus_missing,
	hr_certificateStatus_nouser,
} hr_certificateStatus;
hr_certificateStatus hr_certificateStatus_enumFromString(NSString *string);
NSString * hr_certificateStatus_stringFromEnum(hr_certificateStatus enumValue);
@interface hr_getOneTimeTokenRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * userToken;
	NSNumber * type;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_getOneTimeTokenRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * userToken;
@property (nonatomic, retain) NSNumber * type;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_getOneTimeTokenResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * userToken;
	NSString * serverToken;
	NSDate * notValidAfter;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_getOneTimeTokenResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * userToken;
@property (nonatomic, retain) NSString * serverToken;
@property (nonatomic, retain) NSDate * notValidAfter;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_passwordChangeV2Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * targetUser;
	NSString * usrToken;
	NSString * serverToken;
	NSString * authHash;
	NSData * xnewHA1;
	NSData * xnewHA1B;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_passwordChangeV2Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSString * usrToken;
@property (nonatomic, retain) NSString * serverToken;
@property (nonatomic, retain) NSString * authHash;
@property (nonatomic, retain) NSData * xnewHA1;
@property (nonatomic, retain) NSData * xnewHA1B;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_passwordChangeV2Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSNumber * result;
	NSString * reason;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_passwordChangeV2Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSNumber * result;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_authCheckV3Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSString * authHash;
	hr_trueFalse unregisterIfOK;
	NSString * resourceId;
	NSString * appVersion;
	NSString * capabilities;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_authCheckV3Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSString * authHash;
@property (nonatomic, assign) hr_trueFalse unregisterIfOK;
@property (nonatomic, retain) NSString * resourceId;
@property (nonatomic, retain) NSString * appVersion;
@property (nonatomic, retain) NSString * capabilities;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_authCheckV3Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_trueFalse authHashValid;
	hr_trueFalseNA certValid;
	hr_certificateStatus certStatus;
	hr_trueFalse forcePasswordChange;
	NSNumber * errCode;
	NSNumber * storedFilesNum;
	NSDate * serverTime;
	NSString * licenseType;
	NSDate * accountIssued;
	NSDate * accountExpires;
	NSDate * firstAuthCheckDate;
	NSDate * lastAuthCheckDate;
	NSDate * firstLoginDate;
	NSDate * firstUserAddDate;
	NSDate * accountLastActivity;
	NSDate * accountLastPassChange;
	USBoolean * accountDisabled;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_authCheckV3Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, assign) hr_trueFalse authHashValid;
@property (nonatomic, assign) hr_trueFalseNA certValid;
@property (nonatomic, assign) hr_certificateStatus certStatus;
@property (nonatomic, assign) hr_trueFalse forcePasswordChange;
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSNumber * storedFilesNum;
@property (nonatomic, retain) NSDate * serverTime;
@property (nonatomic, retain) NSString * licenseType;
@property (nonatomic, retain) NSDate * accountIssued;
@property (nonatomic, retain) NSDate * accountExpires;
@property (nonatomic, retain) NSDate * firstAuthCheckDate;
@property (nonatomic, retain) NSDate * lastAuthCheckDate;
@property (nonatomic, retain) NSDate * firstLoginDate;
@property (nonatomic, retain) NSDate * firstUserAddDate;
@property (nonatomic, retain) NSDate * accountLastActivity;
@property (nonatomic, retain) NSDate * accountLastPassChange;
@property (nonatomic, retain) USBoolean * accountDisabled;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_certificateRequestElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * certificateHash;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_certificateRequestElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * certificateHash;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_getCertificateRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *element;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_getCertificateRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addElement:(hr_certificateRequestElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * element;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_certificateWrapper : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSData * certificate;
	hr_certificateStatus status;
	hr_certificateStatus providedCertStatus;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_certificateWrapper *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSData * certificate;
@property (nonatomic, assign) hr_certificateStatus status;
@property (nonatomic, assign) hr_certificateStatus providedCertStatus;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_getCertificateResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_getCertificateResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addReturn_:(hr_certificateWrapper *)toAdd;
@property (nonatomic, readonly) NSMutableArray * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_signCertificateRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * usrToken;
	NSString * serverToken;
	NSString * authHash;
	NSData * CSR;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_signCertificateRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * usrToken;
@property (nonatomic, retain) NSString * serverToken;
@property (nonatomic, retain) NSString * authHash;
@property (nonatomic, retain) NSData * CSR;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_signCertificateResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_certificateWrapper * certificate;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_signCertificateResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_certificateWrapper * certificate;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_signCertificateV2Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * usrToken;
	NSString * serverToken;
	NSString * authHash;
	NSData * CSR;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_signCertificateV2Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * usrToken;
@property (nonatomic, retain) NSString * serverToken;
@property (nonatomic, retain) NSString * authHash;
@property (nonatomic, retain) NSData * CSR;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_signCertificateV2Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_certificateWrapper * certificate;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_signCertificateV2Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_certificateWrapper * certificate;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_whitelistAction_none = 0,
	hr_whitelistAction_add,
	hr_whitelistAction_remove,
	hr_whitelistAction_enable,
	hr_whitelistAction_disable,
	hr_whitelistAction_nothing,
} hr_whitelistAction;
hr_whitelistAction hr_whitelistAction_enumFromString(NSString *string);
NSString * hr_whitelistAction_stringFromEnum(hr_whitelistAction enumValue);
typedef enum {
	hr_contactlistAction_none = 0,
	hr_contactlistAction_add,
	hr_contactlistAction_update,
	hr_contactlistAction_remove,
	hr_contactlistAction_enable,
	hr_contactlistAction_disable,
	hr_contactlistAction_nothing,
} hr_contactlistAction;
hr_contactlistAction hr_contactlistAction_enumFromString(NSString *string);
NSString * hr_contactlistAction_stringFromEnum(hr_contactlistAction enumValue);
@interface hr_contactlistReturn : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSString * user;
	NSNumber * resultCode;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactlistReturn *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSNumber * resultCode;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_contactlistChangeRequestElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	hr_userIdentifier * user;
	hr_contactlistAction action;
	hr_whitelistAction whitelistAction;
	NSString * displayName;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactlistChangeRequestElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) hr_userIdentifier * user;
@property (nonatomic, assign) hr_contactlistAction action;
@property (nonatomic, assign) hr_whitelistAction whitelistAction;
@property (nonatomic, retain) NSString * displayName;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_contactListElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * owner;
	NSNumber * userid;
	NSString * alias;
	NSString * usersip;
	hr_userPresenceStatus presenceStatus;
	hr_enabledDisabled contactlistStatus;
	hr_userWhitelistStatus whitelistStatus;
	USBoolean * hideInContactList;
	NSString * displayName;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactListElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * userid;
@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSString * usersip;
@property (nonatomic, assign) hr_userPresenceStatus presenceStatus;
@property (nonatomic, assign) hr_enabledDisabled contactlistStatus;
@property (nonatomic, assign) hr_userWhitelistStatus whitelistStatus;
@property (nonatomic, retain) USBoolean * hideInContactList;
@property (nonatomic, retain) NSString * displayName;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_whitelistRequestElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	hr_userIdentifier * user;
	hr_whitelistAction action;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_whitelistRequestElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) hr_userIdentifier * user;
@property (nonatomic, assign) hr_whitelistAction action;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_whitelistElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * userid;
	NSString * usersip;
	hr_userWhitelistStatus whitelistStatus;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_whitelistElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * userid;
@property (nonatomic, retain) NSString * usersip;
@property (nonatomic, assign) hr_userWhitelistStatus whitelistStatus;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_whitelistRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *whitelistrequestElement;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_whitelistRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addWhitelistrequestElement:(hr_whitelistRequestElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * whitelistrequestElement;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_whitelistResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_whitelistResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addReturn_:(NSNumber *)toAdd;
@property (nonatomic, readonly) NSMutableArray * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_whitelistGetRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_whitelistGetRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_whitelistGetResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_whitelistGetResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addReturn_:(hr_whitelistElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_contactlistGetRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSMutableArray *users;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactlistGetRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
- (void)addUsers:(hr_userIdentifier *)toAdd;
@property (nonatomic, readonly) NSMutableArray * users;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_contactlistGetResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *contactlistEntry;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactlistGetResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addContactlistEntry:(hr_contactListElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * contactlistEntry;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_contactlistChangeRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *contactlistChangeRequestElement;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactlistChangeRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addContactlistChangeRequestElement:(hr_contactlistChangeRequestElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * contactlistChangeRequestElement;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_contactlistChangeResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *return_;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_contactlistChangeResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addReturn_:(hr_contactlistReturn *)toAdd;
@property (nonatomic, readonly) NSMutableArray * return_;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistElementV2 : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * owner;
	NSNumber * userid;
	NSString * alias;
	NSString * usersip;
	hr_userPresenceStatus presenceStatus;
	hr_enabledDisabled contactlistStatus;
	hr_userWhitelistStatus whitelistStatus;
	USBoolean * hideInContactList;
	NSString * displayName;
	NSDate * dateLastChange;
	NSString * auxData;
	NSNumber * primaryGroup;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistElementV2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * userid;
@property (nonatomic, retain) NSString * alias;
@property (nonatomic, retain) NSString * usersip;
@property (nonatomic, assign) hr_userPresenceStatus presenceStatus;
@property (nonatomic, assign) hr_enabledDisabled contactlistStatus;
@property (nonatomic, assign) hr_userWhitelistStatus whitelistStatus;
@property (nonatomic, retain) USBoolean * hideInContactList;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSDate * dateLastChange;
@property (nonatomic, retain) NSString * auxData;
@property (nonatomic, retain) NSNumber * primaryGroup;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistElementListV2 : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *elements;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistElementListV2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addElements:(hr_clistElementV2 *)toAdd;
@property (nonatomic, readonly) NSMutableArray * elements;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistGetV2Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
	hr_sipList * users;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistGetV2Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
@property (nonatomic, retain) hr_sipList * users;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistGetV2Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
	NSNumber * errCode;
	hr_clistElementListV2 * contactList;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistGetV2Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_clistElementListV2 * contactList;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistChangeRequestElementV2 : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_userIdentifier * user;
	hr_contactlistAction action;
	NSString * displayName;
	NSString * auxData;
	hr_whitelistAction whitelistAction;
	NSNumber * primaryGroup;
	NSString * targetUser;
	USBoolean * managePairingRequests;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistChangeRequestElementV2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_userIdentifier * user;
@property (nonatomic, assign) hr_contactlistAction action;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * auxData;
@property (nonatomic, assign) hr_whitelistAction whitelistAction;
@property (nonatomic, retain) NSNumber * primaryGroup;
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) USBoolean * managePairingRequests;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistChangeListV2 : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *changes;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistChangeListV2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addChanges:(hr_clistChangeRequestElementV2 *)toAdd;
@property (nonatomic, readonly) NSMutableArray * changes;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistChangeResultV2 : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * resultCode;
	NSString * targetUser;
	NSString * user;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistChangeResultV2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * resultCode;
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistChangeV2Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_clistChangeListV2 * changes;
	USBoolean * managePairingRequests;
	NSString * targetUser;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistChangeV2Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_clistChangeListV2 * changes;
@property (nonatomic, retain) USBoolean * managePairingRequests;
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistChangeResultListV2 : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *results;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistChangeResultListV2 *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addResults:(hr_clistChangeResultV2 *)toAdd;
@property (nonatomic, readonly) NSMutableArray * results;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_clistChangeV2Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_clistChangeResultListV2 * resultList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_clistChangeV2Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_clistChangeResultListV2 * resultList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_cgroupAction_none = 0,
	hr_cgroupAction_add,
	hr_cgroupAction_update,
	hr_cgroupAction_remove,
} hr_cgroupAction;
hr_cgroupAction hr_cgroupAction_enumFromString(NSString *string);
NSString * hr_cgroupAction_stringFromEnum(hr_cgroupAction enumValue);
@interface hr_cgroup : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * id_;
	NSString * groupKey;
	NSString * groupType;
	NSString * owner;
	NSString * groupName;
	NSDate * dateLastChange;
	NSString * auxData;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroup *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * id_;
@property (nonatomic, retain) NSString * groupKey;
@property (nonatomic, retain) NSString * groupType;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NSDate * dateLastChange;
@property (nonatomic, retain) NSString * auxData;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *groups;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addGroups:(hr_cgroup *)toAdd;
@property (nonatomic, readonly) NSMutableArray * groups;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupIdList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *ids;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupIdList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addIds:(NSNumber *)toAdd;
@property (nonatomic, readonly) NSMutableArray * ids;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupGetRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * targetUser;
	hr_cgroupIdList * idList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupGetRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) hr_cgroupIdList * idList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupGetResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
	NSNumber * errCode;
	hr_cgroupList * groupList;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupGetResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_cgroupList * groupList;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupUpdateRequestElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_cgroupAction action;
	NSNumber * id_;
	NSString * groupKey;
	NSString * groupType;
	NSString * owner;
	NSString * groupName;
	NSString * auxData;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupUpdateRequestElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, assign) hr_cgroupAction action;
@property (nonatomic, retain) NSNumber * id_;
@property (nonatomic, retain) NSString * groupKey;
@property (nonatomic, retain) NSString * groupType;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSString * groupName;
@property (nonatomic, retain) NSString * auxData;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupUpdateRequestList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *updates;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupUpdateRequestList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addUpdates:(hr_cgroupUpdateRequestElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * updates;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupUpdateResult : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * resultCode;
	NSString * targetUser;
	NSNumber * groupId;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupUpdateResult *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * resultCode;
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSNumber * groupId;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupUpdateResultList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *results;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupUpdateResultList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addResults:(hr_cgroupUpdateResult *)toAdd;
@property (nonatomic, readonly) NSMutableArray * results;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupUpdateRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_cgroupUpdateRequestList * updatesList;
	NSString * targetUser;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupUpdateRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_cgroupUpdateRequestList * updatesList;
@property (nonatomic, retain) NSString * targetUser;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_cgroupUpdateResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_cgroupUpdateResultList * resultList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_cgroupUpdateResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_cgroupUpdateResultList * resultList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftDHKey : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSData * aEncBlock;
	NSData * sEncBlock;
	NSString * nonce1;
	NSString * nonce2;
	NSData * sig1;
	NSData * sig2;
	NSDate * expires;
	NSNumber * protocolVersion;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
	NSString * creatorCertInfo;
	NSString * userCertInfo;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDHKey *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSData * aEncBlock;
@property (nonatomic, retain) NSData * sEncBlock;
@property (nonatomic, retain) NSString * nonce1;
@property (nonatomic, retain) NSString * nonce2;
@property (nonatomic, retain) NSData * sig1;
@property (nonatomic, retain) NSData * sig2;
@property (nonatomic, retain) NSDate * expires;
@property (nonatomic, retain) NSNumber * protocolVersion;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
@property (nonatomic, retain) NSString * creatorCertInfo;
@property (nonatomic, retain) NSString * userCertInfo;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_sipDatePair : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * sip;
	NSDate * dt;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_sipDatePair *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * sip;
@property (nonatomic, retain) NSDate * dt;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_sipDatePairList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *sipdate;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_sipDatePairList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addSipdate:(hr_sipDatePair *)toAdd;
@property (nonatomic, readonly) NSMutableArray * sipdate;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftAddDHKeysRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *dhkeys;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftAddDHKeysRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addDhkeys:(hr_ftDHKey *)toAdd;
@property (nonatomic, readonly) NSMutableArray * dhkeys;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftAddDHKeysReturnList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *code;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftAddDHKeysReturnList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addCode:(NSNumber *)toAdd;
@property (nonatomic, readonly) NSMutableArray * code;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftAddDHKeysResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_ftAddDHKeysReturnList * result;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftAddDHKeysResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_ftAddDHKeysReturnList * result;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftNonceList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *nonce;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftNonceList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addNonce:(NSString *)toAdd;
@property (nonatomic, readonly) NSMutableArray * nonce;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftRemoveDHKeysRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	USBoolean * deleteAll;
	hr_ftNonceList * nonceList;
	hr_sipList * users;
	hr_sipDatePairList * userDateList;
	NSDate * deleteOlderThan;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftRemoveDHKeysRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) USBoolean * deleteAll;
@property (nonatomic, retain) hr_ftNonceList * nonceList;
@property (nonatomic, retain) hr_sipList * users;
@property (nonatomic, retain) hr_sipDatePairList * userDateList;
@property (nonatomic, retain) NSDate * deleteOlderThan;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftRemoveDHKeysResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftRemoveDHKeysResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_ftDHkeyState_none = 0,
	hr_ftDHkeyState_ready,
	hr_ftDHkeyState_used,
	hr_ftDHkeyState_expired,
	hr_ftDHkeyState_uploaded,
} hr_ftDHkeyState;
hr_ftDHkeyState hr_ftDHkeyState_enumFromString(NSString *string);
NSString * hr_ftDHkeyState_stringFromEnum(hr_ftDHkeyState enumValue);
@interface hr_ftDHKeyUserInfo : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * nonce2;
	hr_ftDHkeyState status;
	NSDate * expires;
	NSDate * xcreated;
	NSString * creatorCertInfo;
	NSString * userCertInfo;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDHKeyUserInfo *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * nonce2;
@property (nonatomic, assign) hr_ftDHkeyState status;
@property (nonatomic, retain) NSDate * expires;
@property (nonatomic, retain) NSDate * xcreated;
@property (nonatomic, retain) NSString * creatorCertInfo;
@property (nonatomic, retain) NSString * userCertInfo;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftDHKeyUserStats : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSNumber * readyCount;
	NSNumber * usedCount;
	NSNumber * expiredCount;
	NSNumber * uploadedCount;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDHKeyUserStats *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSNumber * readyCount;
@property (nonatomic, retain) NSNumber * usedCount;
@property (nonatomic, retain) NSNumber * expiredCount;
@property (nonatomic, retain) NSNumber * uploadedCount;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftDHKeyUserInfoArr : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *keyinfo;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDHKeyUserInfoArr *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addKeyinfo:(hr_ftDHKeyUserInfo *)toAdd;
@property (nonatomic, readonly) NSMutableArray * keyinfo;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftDHKeyUserStatsArr : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *keystats;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDHKeyUserStatsArr *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addKeystats:(hr_ftDHKeyUserStats *)toAdd;
@property (nonatomic, readonly) NSMutableArray * keystats;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetStoredDHKeysInfoRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_sipList * users;
	USBoolean * detailed;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetStoredDHKeysInfoRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_sipList * users;
@property (nonatomic, retain) USBoolean * detailed;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetStoredDHKeysInfoResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_ftDHKeyUserInfoArr * info;
	hr_ftDHKeyUserStatsArr * stats;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetStoredDHKeysInfoResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_ftDHKeyUserInfoArr * info;
@property (nonatomic, retain) hr_ftDHKeyUserStatsArr * stats;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetDHKeyRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSNumber * protocolVersion;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetDHKeyRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSNumber * protocolVersion;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetDHKeyResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * user;
	NSData * aEncBlock;
	NSData * sEncBlock;
	NSData * sig1;
	NSDate * xcreated;
	NSDate * expires;
	NSNumber * protocolVersion;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetDHKeyResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSData * aEncBlock;
@property (nonatomic, retain) NSData * sEncBlock;
@property (nonatomic, retain) NSData * sig1;
@property (nonatomic, retain) NSDate * xcreated;
@property (nonatomic, retain) NSDate * expires;
@property (nonatomic, retain) NSNumber * protocolVersion;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetDHKeyPart2Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * user;
	NSString * nonce1;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetDHKeyPart2Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * nonce1;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetDHKeyPart2Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * user;
	NSString * nonce2;
	NSData * sig2;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetDHKeyPart2Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * nonce2;
@property (nonatomic, retain) NSData * sig2;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftDeleteFilesRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	USBoolean * deleteAll;
	hr_ftNonceList * nonceList;
	hr_sipList * users;
	NSDate * deleteOlderThan;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDeleteFilesRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) USBoolean * deleteAll;
@property (nonatomic, retain) hr_ftNonceList * nonceList;
@property (nonatomic, retain) hr_sipList * users;
@property (nonatomic, retain) NSDate * deleteOlderThan;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftDeleteFilesResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftDeleteFilesResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftStoredFile : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * sender;
	NSDate * sentDate;
	NSString * nonce2;
	NSString * hashMeta;
	NSString * hashPack;
	NSNumber * sizeMeta;
	NSNumber * sizePack;
	NSData * key;
	NSNumber * protocolVersion;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftStoredFile *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * sender;
@property (nonatomic, retain) NSDate * sentDate;
@property (nonatomic, retain) NSString * nonce2;
@property (nonatomic, retain) NSString * hashMeta;
@property (nonatomic, retain) NSString * hashPack;
@property (nonatomic, retain) NSNumber * sizeMeta;
@property (nonatomic, retain) NSNumber * sizePack;
@property (nonatomic, retain) NSData * key;
@property (nonatomic, retain) NSNumber * protocolVersion;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftStoredFileList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *file;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftStoredFileList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addFile:(hr_ftStoredFile *)toAdd;
@property (nonatomic, readonly) NSMutableArray * file;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetStoredFilesRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	USBoolean * getAll;
	hr_sipList * users;
	hr_ftNonceList * nonceList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetStoredFilesRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) USBoolean * getAll;
@property (nonatomic, retain) hr_sipList * users;
@property (nonatomic, retain) hr_ftNonceList * nonceList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_ftGetStoredFilesResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_ftStoredFileList * storedFile;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_ftGetStoredFilesResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_ftStoredFileList * storedFile;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestFetchRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * tstamp;
	NSString * from;
	USBoolean * fetchMyRequests;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestFetchRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * tstamp;
@property (nonatomic, retain) NSString * from;
@property (nonatomic, retain) USBoolean * fetchMyRequests;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
typedef enum {
	hr_pairingRequestResolutionEnum_none = 0,
	hr_pairingRequestResolutionEnum_accepted,
	hr_pairingRequestResolutionEnum_denied,
	hr_pairingRequestResolutionEnum_blocked,
	hr_pairingRequestResolutionEnum_reverted,
} hr_pairingRequestResolutionEnum;
hr_pairingRequestResolutionEnum hr_pairingRequestResolutionEnum_enumFromString(NSString *string);
NSString * hr_pairingRequestResolutionEnum_stringFromEnum(hr_pairingRequestResolutionEnum enumValue);
@interface hr_pairingRequestElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * id_;
	NSString * owner;
	NSNumber * tstamp;
	NSString * fromUser;
	NSString * fromUserResource;
	NSDate * dateLastChange;
	NSString * fromUserAux;
	NSString * requestMessage;
	NSString * requestAux;
	hr_pairingRequestResolutionEnum resolution;
	NSString * resolutionResource;
	NSNumber * resolutionTstamp;
	NSString * resolutionMessage;
	NSString * resolutionAux;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * id_;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * tstamp;
@property (nonatomic, retain) NSString * fromUser;
@property (nonatomic, retain) NSString * fromUserResource;
@property (nonatomic, retain) NSDate * dateLastChange;
@property (nonatomic, retain) NSString * fromUserAux;
@property (nonatomic, retain) NSString * requestMessage;
@property (nonatomic, retain) NSString * requestAux;
@property (nonatomic, assign) hr_pairingRequestResolutionEnum resolution;
@property (nonatomic, retain) NSString * resolutionResource;
@property (nonatomic, retain) NSNumber * resolutionTstamp;
@property (nonatomic, retain) NSString * resolutionMessage;
@property (nonatomic, retain) NSString * resolutionAux;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *elements;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addElements:(hr_pairingRequestElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * elements;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestFetchResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_pairingRequestList * requestList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestFetchResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_pairingRequestList * requestList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestInsertRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * to;
	NSString * fromResource;
	NSString * fromAux;
	NSString * requestMessage;
	NSString * requestAux;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestInsertRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * to;
@property (nonatomic, retain) NSString * fromResource;
@property (nonatomic, retain) NSString * fromAux;
@property (nonatomic, retain) NSString * requestMessage;
@property (nonatomic, retain) NSString * requestAux;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestInsertResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestInsertResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestUpdateElement : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	USBoolean * deleteRecord;
	NSNumber * deleteOlderThan;
	NSNumber * id_;
	NSString * owner;
	NSNumber * tstamp;
	NSString * fromUser;
	NSString * fromUserResource;
	NSString * fromUserAux;
	NSString * requestMessage;
	NSString * requestAux;
	hr_pairingRequestResolutionEnum resolution;
	NSString * resolutionResource;
	NSNumber * resolutionTstamp;
	NSString * resolutionMessage;
	NSString * resolutionAux;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestUpdateElement *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) USBoolean * deleteRecord;
@property (nonatomic, retain) NSNumber * deleteOlderThan;
@property (nonatomic, retain) NSNumber * id_;
@property (nonatomic, retain) NSString * owner;
@property (nonatomic, retain) NSNumber * tstamp;
@property (nonatomic, retain) NSString * fromUser;
@property (nonatomic, retain) NSString * fromUserResource;
@property (nonatomic, retain) NSString * fromUserAux;
@property (nonatomic, retain) NSString * requestMessage;
@property (nonatomic, retain) NSString * requestAux;
@property (nonatomic, assign) hr_pairingRequestResolutionEnum resolution;
@property (nonatomic, retain) NSString * resolutionResource;
@property (nonatomic, retain) NSNumber * resolutionTstamp;
@property (nonatomic, retain) NSString * resolutionMessage;
@property (nonatomic, retain) NSString * resolutionAux;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestUpdateList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *updates;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestUpdateList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addUpdates:(hr_pairingRequestUpdateElement *)toAdd;
@property (nonatomic, readonly) NSMutableArray * updates;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestUpdateResultList : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSMutableArray *errCodes;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestUpdateResultList *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
- (void)addErrCodes:(NSNumber *)toAdd;
@property (nonatomic, readonly) NSMutableArray * errCodes;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestUpdateRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	hr_pairingRequestUpdateList * updateList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestUpdateRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) hr_pairingRequestUpdateList * updateList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pairingRequestUpdateResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	hr_pairingRequestUpdateResultList * resultList;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pairingRequestUpdateResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) hr_pairingRequestUpdateResultList * resultList;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_trialEventSaveRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * etype;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_trialEventSaveRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * etype;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_trialEventSaveResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_trialEventSaveResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_trialEventGetRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * etype;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_trialEventGetRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * etype;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_trialEventGetResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * respJSON;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_trialEventGetResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * respJSON;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pushRequestRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * reqJSON;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pushRequestRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * reqJSON;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pushRequestResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * responseJSON;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pushRequestResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * responseJSON;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pushAckRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * reqJSON;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pushAckRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * reqJSON;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_pushAckResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * responseJSON;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_pushAckResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * responseJSON;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_authStateSaveV1Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * secret;
	NSString * nonce;
	NSNumber * appVersionCode;
	NSString * appVersion;
	NSString * identifier;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_authStateSaveV1Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * secret;
@property (nonatomic, retain) NSString * nonce;
@property (nonatomic, retain) NSNumber * appVersionCode;
@property (nonatomic, retain) NSString * appVersion;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_authStateSaveV1Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSNumber * timestamp;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_authStateSaveV1Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSNumber * timestamp;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_authStateFetchV1Request : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * nonce;
	NSString * userName;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_authStateFetchV1Request *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * nonce;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_authStateFetchV1Response : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * secret;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_authStateFetchV1Response *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * secret;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_accountingSaveRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * requestBody;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountingSaveRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * requestBody;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_accountingSaveResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * errText;
	NSString * responseBody;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountingSaveResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * errText;
@property (nonatomic, retain) NSString * responseBody;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_accountingFetchRequest : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSString * requestBody;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountingFetchRequest *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSString * requestBody;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
@interface hr_accountingFetchResponse : NSObject <NSCoding> {
SOAPSigner *soapSigner;
/* elements */
	NSNumber * errCode;
	NSString * errText;
	NSString * responseBody;
	NSNumber * version;
	NSNumber * auxVersion;
	NSString * auxJSON;
/* attributes */
}
- (NSString *)nsPrefix;
- (xmlNodePtr)xmlNodeForDoc:(xmlDocPtr)doc elementName:(NSString *)elName elementNSPrefix:(NSString *)elNSPrefix;
- (void)addAttributesToNode:(xmlNodePtr)node;
- (void)addElementsToNode:(xmlNodePtr)node;
+ (hr_accountingFetchResponse *)deserializeNode:(xmlNodePtr)cur;
- (void)deserializeAttributesFromNode:(xmlNodePtr)cur;
- (void)deserializeElementsFromNode:(xmlNodePtr)cur;
@property (retain) SOAPSigner *soapSigner;
/* elements */
@property (nonatomic, retain) NSNumber * errCode;
@property (nonatomic, retain) NSString * errText;
@property (nonatomic, retain) NSString * responseBody;
@property (nonatomic, retain) NSNumber * version;
@property (nonatomic, retain) NSNumber * auxVersion;
@property (nonatomic, retain) NSString * auxJSON;
/* attributes */
- (NSDictionary *)attributes;
@end
