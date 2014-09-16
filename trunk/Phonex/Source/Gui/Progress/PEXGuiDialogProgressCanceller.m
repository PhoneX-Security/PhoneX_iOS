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

- (id) initWithController: (PEXGuiController * const) controller Task:(PEXTask * const) task
{
    self = [super initWithController:controller];

    self.task = task;
    [self.task addListener:self];

    return self;
}

- (void) setContent: (PEXGuiDialogUnaryController * const) dialog
{
    [[dialog firstButton] setTitle:(PEXStrU(@"cancel")) forState:UIControlStateNormal];
}

- (void) firstButtonAction
{
    [self.task cancel];
}

- (void) taskEnded:(const PEXTaskEvent *const)event
{
    dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self.dialog dismissViewControllerAnimated:YES completion:nil];
                   });
}

- (void) taskStarted: (const PEXTaskEvent * const) event {}
- (void) taskProgressed: (const PEXTaskEvent * const) event {}
- (void) taskCancelStarted: (const PEXTaskEvent * const) event {}
- (void) taskCancelEnded: (const PEXTaskEvent * const) event {}
- (void) taskCancelProgressed: (const PEXTaskEvent * const) event {}

@end
