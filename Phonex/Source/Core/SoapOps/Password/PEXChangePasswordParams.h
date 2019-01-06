//
// Created by Dusan Klinec on 29.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXChangePasswordParams : NSObject
@property (nonatomic) NSString * userSIP;
@property (nonatomic) NSString * targetUserSIP;
@property (nonatomic) NSString * userOldPass;
@property (nonatomic) NSString * userNewPass;
@property (nonatomic) BOOL derivePasswords;
@property (nonatomic) BOOL rekeyKeyStore;
@property (nonatomic) BOOL rekeyDB;
@end