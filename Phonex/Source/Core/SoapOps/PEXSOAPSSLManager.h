//
// Created by Dusan Klinec on 05.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "USAdditions.h"
#import "PEXUserPrivate.h"

@interface PEXSOAPSSLManager : NSObject <SSLCredentialsManaging>

/**
 * Username to be used with this SSL manager.
 * Can automatically load user certificate, for example.
 */
@property (nonatomic) NSString * userName;

/**
 * Property says whether this SSL manager should support SSL auth.
 * By default is set to YES. If there is all required information
 * set, client auth is enabled.
 */
@property (nonatomic) BOOL supportClientAuth;

/**
 * Initialize with existing private data - contains identity.
 */
-(id) initWithPrivData: (PEXUserPrivate *) privData;

/**
 * Initialize with initialized identity and corresponding user name.
 */
-(id)initWithPrivData:(PEXUserPrivate *)identity andUsername: (NSString *) username;

/**
 * Returns loaded identity.
 */
- (PEXUserPrivate *) getIdentity;

/**
 * Returns YES if client auth is enabled and we have all required information.
 * E.g., certificate and private key.
 */
- (BOOL)isClientAuthPossible;

/**
* Returns true if a given private data structure is valid for SOAP with client certificates.
*/
+ (BOOL)isIdendityUsableForSOAP: (PEXUserPrivate *) privData;

/**
* Perform TLS auth while returning used credential if YES is returned.
*/
- (BOOL)authenticateForChallenge:(NSURLAuthenticationChallenge *)challenge credential: (NSURLCredential **) credential;
@end