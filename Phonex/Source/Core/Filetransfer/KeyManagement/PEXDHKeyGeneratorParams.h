//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXDHKeyGenForUser : NSObject<NSCopying, NSCoding> { }
/**
* User for which to generate DHkeys.
*/
@property(nonatomic) NSString * userSip;

/**
* User certificate (included in signatures).
*/
@property(nonatomic) PEXX509 * userCert;

/**
* Number of DH keys to generate for particular user.
*/
@property(nonatomic) int numKeys;

- (id)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;

- (id)copyWithZone:(NSZone *)zone;

- (BOOL)isEqual:(id)other;

- (BOOL)isEqualToUser:(PEXDHKeyGenForUser *)user;

- (NSUInteger)hash;

- (NSString *)description;
@end


@interface PEXDHKeyGeneratorParams : NSObject <NSCoding, NSCopying>
/**
* My SIP.
*/
@property(nonatomic) NSString * mySip;

/**
* Private key to generate signature with
*/
@property(nonatomic) PEXUserPrivate * privKey;

/**
* List of users to generate keys for. Type: PEXDHKeyGenForUser.
*/
@property(nonatomic) NSMutableArray * userList;

/**
* List of nonce2s to delete from the server. Type: NSString.
*/
@property(nonatomic) NSMutableArray * deleteNonce2List;

/**
* Default number of keys to add.
*/
@property(nonatomic) int numKeys;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToParams:(PEXDHKeyGeneratorParams *)params;
- (NSUInteger)hash;
- (NSString *)description;
@end