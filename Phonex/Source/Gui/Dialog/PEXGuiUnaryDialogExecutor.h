//
// Created by Matej Oravec on 01/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiDialogUnaryListener.h"
#import "PEXGuiExecutor.h"

@interface PEXGuiUnaryDialogExecutor : PEXGuiExecutor<PEXGuiDialogUnaryListener>

- (id) initWithController: (PEXGuiController * const) parentController;

@property (nonatomic) NSString * primaryButtonText;
@property (nonatomic, copy) void (^primaryAction)(void);
@property (nonatomic) NSString * text;
@property (nonatomic) NSAttributedString * attributedText;

@end