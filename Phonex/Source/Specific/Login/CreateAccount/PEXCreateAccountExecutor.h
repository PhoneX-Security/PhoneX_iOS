//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"
#import "PEXTaskListener.h"

@class PEXCreateAccountHolder;
@class PEXGuiCreateAccountController;

@interface PEXNewAccountInfo : NSObject

@property (nonatomic) NSString * username;
@property (nonatomic) NSString * tempPassword;
@property (nonatomic) NSDate * expirationDate;

@end

@protocol PEXNewAccountCreatedListener

- (void) newAccountCreated: (const PEXNewAccountInfo * const) info;

@end

@interface PEXCreateAccountExecutor : PEXGuiExecutor<PEXTaskListener>

@property (nonatomic) PEXCreateAccountHolder * holder;
@property (nonatomic) id<PEXNewAccountCreatedListener> listener;

@end