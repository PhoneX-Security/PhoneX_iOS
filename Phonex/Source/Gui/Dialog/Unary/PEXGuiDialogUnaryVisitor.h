//
//  PEXDialogUnaryDialogVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 17/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXGuiDialogUnaryController_Friend.h"

typedef void (^PEXDialogActionListenerBlock)(PEXGuiController *);

@protocol PEXGuiDialogUnaryListener;

@interface PEXGuiDialogUnaryVisitor : NSObject

@property (nonatomic) NSString * primaryButtonTitle;

- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
                         listener: (id<PEXGuiDialogUnaryListener>) listener;

- (id)initWithDialogSubcontroller: (PEXGuiController * const) controller
                    primaryAction: (PEXDialogActionListenerBlock) primaryAction;

- (PEXGuiController *) subcontroller;

// PEXGuiController workflow like ... called in appropriate methods
- (void) setContent: (PEXGuiDialogUnaryController * const) dialog;
- (void) setBehavior: (PEXGuiDialogUnaryController * const) dialog;

@end
