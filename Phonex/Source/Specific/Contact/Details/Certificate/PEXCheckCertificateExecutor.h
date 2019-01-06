//
// Created by Matej Oravec on 23/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"
#import "PEXTaskListener.h"

@class PEXDbContact;


@interface PEXCheckCertificateExecutor : PEXGuiExecutor<PEXTaskListener>

@property (nonatomic) PEXDbContact * contact;

@end