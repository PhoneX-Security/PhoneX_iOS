//
//  PEXGuiDialogProgressCanceller.m
//  Phonex
//
//  Created by Matej Oravec on 30/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiDialogProgressCanceller.h"
#import "PEXGuiDialogUnaryVisitor_Protected.h"

#import "PEXTask.h"

@interface PEXGuiDialogProgressCanceller ()

@property (nonatomic, weak) PEXTask * task;

@end

@implementation PEXGuiDialogProgressCanceller


- (void) setTheTask: (PEXTask * const) task
{
    self.task = task;
    [self.task addListener:self];
}

- (id) initWithController: (PEXGuiController * const) controller
{
    self = [super initWithDialogSubcontroller:controller listener:nil];

    return self;
}

- (void) setContent: (PEXGuiDialogUnaryController * const) dialog
{
    [[dialog primaryButton] setTitle:(PEXStrU(@"B_cancel")) forState:UIControlStateNormal];
}

- (void) finishPrimary
{
    [self.task cancel];
}

- (void) taskEnded:(const PEXTaskEvent *const)event
{
    self.howToDismiss();
}

- (void) taskStarted: (const PEXTaskEvent * const) event { }
- (void) taskProgressed: (const PEXTaskEvent * const) event { }
- (void) taskCancelStarted: (const PEXTaskEvent * const) event { }
- (void) taskCancelEnded: (const PEXTaskEvent * const) event { }
- (void) taskCancelProgressed: (const PEXTaskEvent * const) event { }

@end
