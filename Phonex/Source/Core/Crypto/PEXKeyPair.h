//
//  PEXKeyPair.h
//  Phonex
//
//  Created by Dusan Klinec on 18.09.14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXKeyPair : NSObject
@property(nonatomic, assign) SecKeyRef privKey, pubKey;
-(id) initWithPrivKey: (SecKeyRef) aPrivKey andPubKey: (SecKeyRef) aPubKey;
@end
