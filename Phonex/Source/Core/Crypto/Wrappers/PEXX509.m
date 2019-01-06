//
// Created by Dusan Klinec on 10.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXX509.h"
#import "PEXCryptoUtils.h"

@interface PEXX509 ()
@property (nonatomic) X509 * cert;
@end

@implementation PEXX509 {

}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.cert = NULL;
    }

    return self;
}

- (id)initWith:(X509 *)aCrt {
    self = [self init];
    self.cert = aCrt;
    return self;
}

- (void) dealloc {
    if (![self isAllocated]){
        return;
    }

    [self freeBuffer];
}

- (BOOL)isAllocated {
    return self.cert!=NULL;
}

- (void)freeBuffer {
    if (![self isAllocated]){
        DDLogError(@"Buffer is already deallocated");
        return;
    }

    X509_free(self.cert);
    self.cert=NULL;
}

- (X509 *)getRaw {
    return self.cert;
}

- (X509 *)setRaw:(X509 *)aCrt {
    X509 * oldCert = self.cert;
    self.cert = aCrt;
    return oldCert;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.cert=%p", self.cert];
    [description appendString:@">"];
    return description;
}

- (id)copyWithZone:(NSZone *)zone {
    PEXX509 *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        NSString * certPem = [PEXCryptoUtils exportCertificateToPEM:self.cert];
        copy.cert = [PEXCryptoUtils importCertificateFromPEM:nil pem:[certPem dataUsingEncoding:NSASCIIStringEncoding]];
    }

    return copy;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        NSString * certPem = [coder decodeObjectForKey:@"self.crt"];
        if (certPem == nil){
            self.cert = nil;
        } else {
            self.cert = [PEXCryptoUtils importCertificateFromPEM:nil pem:[certPem dataUsingEncoding:NSASCIIStringEncoding]];
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    NSString * certPem = nil;
    if ([self isAllocated]){
        certPem = [PEXCryptoUtils exportCertificateToPEM:self.cert];
    }
    [coder encodeObject:certPem forKey:@"self.crt"];
}

@end