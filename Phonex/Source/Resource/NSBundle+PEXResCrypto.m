//
// Created by Dusan Klinec on 02.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "NSBundle+PEXResCrypto.h"


@implementation NSBundle (PEXResCrypto)

- (NSString *)pathForDHGroupId:(int)groupID {
    if (groupID <= 0 || groupID > 256){
        DDLogError(@"Error: DH group id invalid");
        [NSException raise:@"DH group id invalid" format:@"DH group id invalid %d", groupID];
    }

    NSString * groupName = [NSString stringWithFormat:@"dhparam_4096_1_%04d", groupID];
    NSString *myFile = [self pathForResource: groupName ofType: @"pem"];
    return myFile;
}

- (NSString *)pathForCARoots {
    return [self pathForResource: @"trust-ca" ofType: @"pem"];
}

- (NSString *)pathForCAWebRoots {
    return [self pathForResource: @"trust-web" ofType: @"pem"];
}

- (NSString *)pathForCARootsExpired {
    return [self pathForResource: @"trust-expired" ofType: @"pem"];
}


@end