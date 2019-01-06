//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXX509.h"

@interface PEXCertificate : NSObject
@property (nonatomic) PEXX509 * cert;
- (instancetype)initWithCert:(PEXX509 *)cert;
+ (instancetype)certificateWithCert:(PEXX509 *)cert;
@end