//
// Created by Dusan Klinec on 23.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class hr_ftDHKey;
@class PEXDbDhKey;

/**
* Class represents DH key.
* Stores both database representation and server representation.
* @author ph4r05
*
*/
@interface PEXDHKeyHolder : NSObject
@property(nonatomic) hr_ftDHKey * serverKey;
@property(nonatomic) PEXDbDhKey * dbKey;
@end