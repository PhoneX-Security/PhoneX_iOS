//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXStpBase.h"
#import "PEXCertificate.h"
#import "PEXCryptoUtils.h"


@implementation PEXStpBase {

}
- (instancetype)initWithSender:(NSString *)sender pk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert {
    self = [super init];
    if (self) {
        self.sender = sender;
        self.pk = pk;
        self.remoteCert = remoteCert;
    }

    return self;
}

- (instancetype)initWithPk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert {
    self = [super init];
    if (self) {
        self.pk = pk;
        self.remoteCert = remoteCert;
    }

    return self;
}

+ (instancetype)baseWithPk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert {
    return [[self alloc] initWithPk:pk remoteCert:remoteCert];
}


+ (instancetype)baseWithSender:(NSString *)sender pk:(PEXPrivateKey *)pk remoteCert:(PEXCertificate *)remoteCert {
    return [[self alloc] initWithSender:sender pk:pk remoteCert:remoteCert];
}

-(NSData *) createSignature: (NSData*) dataToSign error: (NSError **) pError {
    return [PEXCryptoUtils sign:dataToSign key:self.pk error:pError];
}

-(BOOL) verifySignature: (NSData *) dataToVerify signature: (NSData *) signature error: (NSError **) pError {
    return [PEXCryptoUtils verify:dataToVerify signature:signature certificate:self.remoteCert error:pError];
}

- (NSData *)buildMessage:(NSData *)payload destination:(NSString *)destination ampType:(PEXProtocolType)ampType ampVersion:(PEXProtocolType)ampVersion error: (NSError **) pError {
    [NSException raise:PEXCallingAbstractMethodExceptionString format:@"Calling an abstract method"];
    return nil;
}

- (PEXStpProcessingResult *)readMessage:(NSData *)serializedStpMessage stpType:(int)stpType stpVersion:(int)stpVersion {
    [NSException raise:PEXCallingAbstractMethodExceptionString format:@"Calling an abstract method"];
    return nil;
}

+ (PEXProtocolType)getProtocolType {
    [NSException raise:PEXCallingAbstractMethodExceptionString format:@"Calling an abstract method"];
    return 0;
}

+ (PEXProtocolVersion)getProtocolVersion {
    [NSException raise:PEXCallingAbstractMethodExceptionString format:@"Calling an abstract method"];
    return 0;
}

- (void)setVersion:(PEXProtocolVersion)transportProtocolVersion {
    // By default does nothing
}


@end