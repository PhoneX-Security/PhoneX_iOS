//
// Created by Matej Oravec on 29/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiDialogUnaryListener.h"

@protocol PEXGuiDialogBinaryListener <PEXGuiDialogUnaryListener>

- (void) secondaryButtonClicked;

@end