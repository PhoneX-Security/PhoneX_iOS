//
// Created by Dusan Klinec on 28.01.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"


@interface PEXGuiPasswordVerificationController : PEXGuiController
@property (nonatomic, copy) NSAttributedString * attributedExtra;
@property (nonatomic, copy) dispatch_block_t onSuccess;

/**
 * Updates attributed text on already displayed controller.
 */
-(void)setAuxText:(NSAttributedString *)string;
@end