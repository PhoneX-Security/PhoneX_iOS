//
// Created by Dusan Klinec on 23.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbContentValues.h"
#import "PEXDbCursor.h"
#import "PEXDbModelBase.h"
#import "PEXDbAppContentProvider.h"
#import "PEXUri.h"
#import "PEXDbContentProvider.h"
#import "PEXDbContentValues.h"
#import "PEXDbCursor.h"

// Naming macro for callers.
#define DBCL(X) PEX_DBCL_##X
#define PEX_CONTACT_HIDDEN_PREFIX "/"

FOUNDATION_EXPORT NSString * const DBCL(TABLE);
FOUNDATION_EXPORT NSString * const DBCL(STATUS_TABLE);

FOUNDATION_EXPORT NSString * const DBCL(FIELD_ID);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_ACCOUNT);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_SIP);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_DISPLAY_NAME);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_CERTIFICATE);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_CERTIFICATE_HASH);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_IN_WHITELIST);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_DATE_CREATED);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_DATE_LAST_CHANGE);
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_ONLINE);

/**
* Textual description of the status.
* @obsolete
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_STATUS);

/**
* Last update of the presence information.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_LAST_UPDATE);

/**
* Presence status type (online/offline, away, DND, oncall, ...).
* Uses protocol buffers enum State.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_STATUS_TYPE);

/**
* Presence custom text provided by user.
* Uses protocol buffers.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_STATUS_TEXT);

/**
* Prefix of the certificate hash provided by presence push notification.
* Serves mainly to signalize certificate change.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_CERT_HASH_PREFIX);

/**
* Certificate not before field (start of the validity of the certificate).
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_CERT_NOT_BEFORE);

/**
* Last certificate update for this contact caused by presence push message.
* May be used to block too-often presence certificate updates (e.g., one in 5 minute interval).
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_LAST_CERT_UPDATE);

/**
* Number of certificate updates in the day(FIELD_PRESENCE_LAST_CERT_UPDATE).
* May be used to block too-often presence certificate updates (e.g., 10 in one day).
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_NUM_CERT_UPDATE);

/**
* Anti-DOS field for the presence caused certificate update.
* May be used by CUSUM (cumulative sum http://www.ist-scampi.org/publications/papers/siris-globecom2004.pdf)
* or by Adaptive threshold algorithm.
* For future extensions.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_PRESENCE_DOS_CERT_UPDATE);

/**
* Number of unread messages from this contact.
* Derived field from messages relation.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_UNREAD_MESSAGES);

/**
* Field indicating this contact should remain hidden from the contact list.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_HIDE_CONTACT);

/**
* Timestamp of the last activity
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_LAST_ACTIVE);

/**
* Timestamp of the last typing notification received from the contact.
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_LAST_TYPING);

/**
* Semicolon separated list of capabilities the user supports.
* Example: ";1.2.0;1.3.2;1.3.3;1.3.3.3;"
*/
FOUNDATION_EXPORT NSString * const DBCL(FIELD_CAPABILITIES);

FOUNDATION_EXPORT NSString * const DBCL(DATE_FORMAT);
FOUNDATION_EXPORT int64_t const DBCL(INVALID_ID);

// SQL Create command for contact list table.
FOUNDATION_EXPORT NSString * const DBCL(CREATE_TABLE);

@interface PEXDbContact : PEXDbModelBase
@property (nonatomic) NSNumber * id;
@property (nonatomic) NSNumber * account;
@property (nonatomic) NSString * sip;
@property (nonatomic) NSString * displayName;
@property (nonatomic) NSData * certificate;
@property (nonatomic) NSString * certificateHash;
@property (nonatomic) BOOL inWhitelist;
@property (nonatomic) NSDate * dateCreated;
@property (nonatomic) NSDate * dateLastModified;
@property (nonatomic) BOOL presenceOnline;
@property (nonatomic) NSString * presenceStatus;
@property (nonatomic) NSDate * presenceLastUpdate;
@property (nonatomic) NSNumber * presenceStatusType;
@property (nonatomic) NSString * presenceStatusText;
@property (nonatomic) NSString * presenceCertHashPrefix;
@property (nonatomic) NSDate * presenceCertNotBefore;
@property (nonatomic) NSDate * presenceLastCertUpdate;
@property (nonatomic) NSNumber * presenceNumCertUpdate;
@property (nonatomic) NSString * presenceDosCertUpdate;
@property (nonatomic) NSNumber * unreadMessages;
@property (nonatomic) NSNumber * hideContact;
@property (nonatomic) NSString * capabilities;
@property (nonatomic) NSDate * lastActive;
@property (nonatomic) NSDate * lastTyping;

+ (NSString *) usernameWithoutDomain: (NSString * const) username;

+(NSString *) getCreateTable;
+(NSArray *) getFullProjection;
+(NSArray *) getNormalProjection;
+(NSArray *) getLightProjection;
+(const PEXDbUri * const) getURI;
+(const PEXDbUri * const) getURIBase;

+(NSString * const) getWhereForId;
+(NSArray*) getWhereForIdArgs: (const NSNumber * const) IdValue;
+(NSString * const) getWhereForSip;
+(NSArray*) getWhereForSipArgs: (NSString * const) sip;

- (instancetype)initWithCursor:(PEXDbCursor *)cursor;
+ (instancetype)contactFromCursor:(PEXDbCursor *)cursor;

- (PEXDbContentValues *) getDbContentValues;

/**
* Removes all contact list entries from the database for given user with given account ID.
* Does not remove dependencies (e.g., messages, logs, files, ...)
*/
+(int) cleanContactList: (PEXDbContentProvider *) cr forUser: (NSNumber *) user;

/**
* Returns array of contacts stored for given account loaded with light projection.
*/
+(NSArray *) getListForAccount: (PEXDbContentProvider *) cr accountId: (int64_t) accId;

/**
* Removes all users with specified user names for given account ID.
*/
+(int) removeContactsForAccount: (PEXDbContentProvider *) cr accountId: (int64_t) accId names: (NSArray *) names;

- (BOOL)isEqualToContact:(const PEXDbContact * const)contact;

/**
* Helper method to retrieve a PEXDbContact object from its account database
*
* @param cr Content provider
* @param sip Sip in text format: e.g: test610@phone-x.net
* @param projection The list of fields you want to retrieve. Must be in FIELD_* of this class.<br/>
* Reducing your requested fields to minimum will improve speed of the request.
* @return A wrapper SipClist object on the request you done. If not found an invalid account with an {@link #id} equals to {@link #INVALID_ID}
*/
+(PEXDbContact *) newProfileFromDbSip: (PEXDbContentProvider *) cr sip: (NSString *) sip projection: (NSArray *) projection;

/**
* Helper method to retrieve a list of PEXDbContact objects from its account database
*
* @param cr Content provider
* @param sip array of sip identifiers.
* @param projection The list of fields you want to retrieve. Must be in FIELD_* of this class.<br/>
* Reducing your requested fields to minimum will improve speed of the request.
* @return A wrapper SipClist object on the request you done. If not found an invalid account with an {@link #id} equals to {@link #INVALID_ID}
*/
+(NSArray *) newProfilesFromDbSip: (PEXDbContentProvider *) cr sip: (NSArray *) sip projection: (NSArray *) projection;

/**
* Updates contact with given ID with provided content values.
*
* @param cr
* @param id
* @param cv
* @return
*/
+(int) updateContact: (PEXDbContentProvider *) cr contactId: (NSNumber *) id contentValues: (PEXDbContentValues *) cv;

/**
* Returns true if a given contact has a given capability.
*/
-(BOOL) hasCapability: (NSString *) capability;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

- (NSString *)description;

- (id)copyWithZone:(NSZone *)zone;

/**
* Adds capability to the string, checks for duplicates in O(mn).
* @param capability
*/
+(NSString *) addCapability: (NSString *) capability capabilities: (NSString *) capabilities;

/**
* Determines whether given capability is among stored ones.
*
* @param capability
* @param capabilities
* @return
*/
+(BOOL) hasCapability: (NSString *) capability capabilities: (NSString *) capabilities;

/**
* Parse given capability to the set. Deserialization routine.
* @param capabilities
* @return
*/
+(NSSet *) getCapabilitiesAsSet: (NSString *) capabilities;
/**
* Assemble capabilities hash set to the string that can be stored to the database.
* Serialization routine.
*
* @param caps
* @return
*/
+(NSString *) assembleCapabilities: (NSSet *) caps;

+ (NSString *)stripHidePrefix:(NSString *)displayName wasPresent: (BOOL *) wasPresent;
+ (NSString *)prependHidePrefix:(NSString *) displayName wasPresent: (BOOL *) wasPresent;
@end