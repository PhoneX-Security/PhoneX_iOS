//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXEVPPKey.h"

@interface PEXPrivateKey : NSObject
@property(nonatomic) PEXEVPPKey * key;
- (instancetype)initWithKey:(PEXEVPPKey *)key;
+ (instancetype)keyWithKey:(PEXEVPPKey *)key;
@end