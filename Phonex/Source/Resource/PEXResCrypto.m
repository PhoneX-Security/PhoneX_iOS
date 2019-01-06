//
// Created by Dusan Klinec on 02.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXResCrypto.h"
#import "NSBundle+PEXResCrypto.h"


@implementation PEXResCrypto {

}
+ (NSData *)loadDHGroupId:(int)groupID {
    NSString * dhGroupPath = [[NSBundle mainBundle] pathForDHGroupId:groupID];
    if (dhGroupPath==nil){
        return nil;
    }

    return [NSData dataWithContentsOfFile:dhGroupPath];
}

+ (NSData *)loadCARoots {
    NSString * caPath = [[NSBundle mainBundle] pathForCARoots];
    if (caPath==nil){
        return nil;
    }

    return [NSData dataWithContentsOfFile:caPath];
}

+ (NSData *)loadCAWebRoots {
    NSString * caPath = [[NSBundle mainBundle] pathForCAWebRoots];
    if (caPath==nil){
        return nil;
    }

    return [NSData dataWithContentsOfFile:caPath];
}

+ (NSData *)loadExpiredCARoots {
    NSString * caPath = [[NSBundle mainBundle] pathForCARootsExpired];
    if (caPath==nil){
        return nil;
    }

    return [NSData dataWithContentsOfFile:caPath];
}

@end