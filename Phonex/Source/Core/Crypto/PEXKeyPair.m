//
//  PEXKeyPair.m
//  Phonex
//
//  Created by Dusan Klinec on 18.09.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXKeyPair.h"

@implementation PEXKeyPair
@synthesize privKey, pubKey;
-(id) initWithPrivKey: (SecKeyRef)aPrivKey andPubKey: (SecKeyRef)aPubKey
{
    self.privKey = aPrivKey;
    self.pubKey = aPubKey;
    return self;
}
@end
