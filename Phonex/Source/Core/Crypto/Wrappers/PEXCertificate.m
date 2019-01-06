//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertificate.h"
#import "PEXX509.h"


@implementation PEXCertificate {

}
- (instancetype)initWithCert:(PEXX509 *)cert {
    self = [super init];
    if (self) {
        self.cert = cert;
    }

    return self;
}

+ (instancetype)certificateWithCert:(PEXX509 *)cert {
    return [[self alloc] initWithCert:cert];
}

@end