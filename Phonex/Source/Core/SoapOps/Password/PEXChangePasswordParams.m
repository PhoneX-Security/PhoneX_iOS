//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXChangePasswordParams.h"


@implementation PEXChangePasswordParams {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.derivePasswords=NO;
        self.rekeyKeyStore=NO;
        self.rekeyDB=NO;
    }

    return self;
}


@end