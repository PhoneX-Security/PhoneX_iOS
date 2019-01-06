//
// Created by Dusan Klinec on 17.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXX509.h"
#import "PEXEVPPKey.h"

/**
 * Contains user private data.
 */
@interface PEXUserPrivate : NSObject <NSCopying>
@property (nonatomic) NSString * username;
@property (nonatomic) NSString * pass;
@property (nonatomic) NSString * pemPass;
@property (nonatomic) NSString * pkcsPass;
@property (nonatomic) NSString * xmppPass;
@property (nonatomic) NSString * sipPass;   //TODO: use sip pass here, set after auth is done.
@property (nonatomic) NSNumber * accountId;
@property (nonatomic) NSUInteger invalidPasswordEntries;

@property (nonatomic) SecIdentityRef identity;
@property (nonatomic) PEXX509 * cert;
@property (nonatomic) PEXEVPPKey * privKey;
@property (nonatomic) NSArray *cacerts;

@property(nonatomic) NSString *pemCAPath;
@property(nonatomic) NSString *pemCrtPath;
@property(nonatomic) NSString *pemKeyPath;

-(SecIdentityRef *) identityPtr;
- (instancetype)initWithUsername:(NSString *)username pass:(NSString *)pass;
+ (instancetype)aPrivateWithUsername:(NSString *)username pass:(NSString *)pass;

/**
* Copies whole object to the provided object.
* Returns given object.
*/
-(instancetype) copyTo: (PEXUserPrivate *) privData;

/**
* Copies only passwords to the provided objects.
* Identity attributes are left alone.
*/
-(instancetype) copyPasswordsTo: (PEXUserPrivate *) privData;

/**
* Copies only identity attributes to the provided object.
* Passwords are left alone.
 */
-(instancetype) copyIdentityTo: (PEXUserPrivate *) privData;

/**
* Copies the whole object to the new object, returns it.
*/
-(instancetype) initCopy;

/**
 * Increments and acquires invalid password reset counter.
 * Modifies preferences.
 */
-(NSInteger) incAndGetInvalidPasswordEntryCounter;

/**
 * Resets invalid password entry counter.
 * Modifies preferences.
 */
-(void) resetInvalidPasswordEntryCounter;

- (id)copyWithZone:(NSZone *)zone;

@end