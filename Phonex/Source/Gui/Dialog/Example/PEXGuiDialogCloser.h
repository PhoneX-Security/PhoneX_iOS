//
//  PEXDialogCloser.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiDialogUnaryVisitor.h"

@interface PEXGuiDialogCloser : PEXGuiDialogUnaryVisitor

@property (nonatomic, copy) void (^finishPrimaryBlock)(void);

@end
