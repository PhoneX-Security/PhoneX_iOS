//
// Created by Dusan Klinec on 05.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSOAPSSLManager.h"
#import "PEXSecurityCenter.h"
#import "PEXPEMPasswd.h"
#import "PEXCryptoUtils.h"
#import "PEXPKCS12Passwd.h"
#import "PEXUserPrivate.h"

@interface  PEXSOAPSSLManager () { }
@property (nonatomic) PEXUserPrivate *privData;
@end

@implementation PEXSOAPSSLManager {

}

- (id) init {
    self = [super init];
    if (self){
        self.privData = nil;
        self.userName = nil;
        self.supportClientAuth = YES;
    }

    return self;
}

- (id)initWithPrivData:(PEXUserPrivate *)privData {
    return [self initWithPrivData:privData andUsername:[privData username]];
}

- (id)initWithPrivData:(PEXUserPrivate *)identity andUsername:(NSString *)username {
    self = [self init];
    if (self){
        self.privData = identity;
        self.userName = username;
    }

    return self;
}

- (PEXUserPrivate *)getIdentity {
    return self.privData;
}

- (BOOL)canAuthenticateForAuthenticationMethod:(NSString *)authMethod {
    return [authMethod isEqualToString:NSURLAuthenticationMethodServerTrust]
            || ([self isClientAuthPossible] && [authMethod isEqualToString:NSURLAuthenticationMethodClientCertificate]);
}

- (BOOL)isClientAuthPossible {
    return [self supportClientAuth] && [self userName]!=nil && [PEXSOAPSSLManager isIdendityUsableForSOAP:self.privData];
}

+ (BOOL)isIdendityUsableForSOAP:(PEXUserPrivate *)privData {
    return privData!=nil && privData.identity!=nil;
}

- (BOOL)authenticateForChallenge:(NSURLAuthenticationChallenge *)challenge {
    return [self authenticateForChallenge:challenge credential:NULL];
}

- (BOOL)authenticateForChallenge:(NSURLAuthenticationChallenge *)challenge credential: (NSURLCredential **) credential {
    if ([challenge previousFailureCount] > 0) {
        DDLogWarn(@"authenticateForChallenge: failure count too big!");
        return NO;
    }

    NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];

    // server authentication - NSURLAuthenticationMethodServerTrust
    if ([protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {

        return [PEXSecurityCenter validateTrustForChallenge:challenge credential:credential];

    } else if ([self isClientAuthPossible] &&
            [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodClientCertificate])
    {
        return [PEXSecurityCenter provideClientCertificateForChallenge:challenge
                                                            credential:credential
                                                           privateData:self.privData];
    }

    [NSException raise:@"Authentication method not supported" format:@"%@ not supported.", [protectionSpace authenticationMethod]];
    return NO;
}


@end