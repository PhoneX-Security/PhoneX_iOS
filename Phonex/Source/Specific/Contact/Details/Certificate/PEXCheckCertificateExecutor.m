//
// Created by Matej Oravec on 23/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCheckCertificateExecutor.h"
#import "PEXGuiProgressController.h"
#import "PEXGuiWindowController.h"
#import "PEXCheckCertificateTask.h"
#import "PEXDbContact.h"
#import "PEXGuiContactDetailsController.h"
#import "PEXGuiFactory.h"


@interface PEXCheckCertificateExecutor ()

@property (nonatomic) PEXCheckCertificateTask *task;

@end

@implementation PEXCheckCertificateExecutor {

}

- (void) show
{
    PEXGuiProgressController * const progress = [[PEXGuiProgressController alloc] init];
    progress.showProgressBar = false;

    PEXGuiWindowController * const taskWindowCOntroller =
            [[PEXGuiWindowController alloc] initWithViewController:progress];

    PEXCheckCertificateTask * const task = [[PEXCheckCertificateTask alloc] init];

    task.contact = self.contact;

    [progress setTheTask:task];
    self.task = task;

    [task addListener:self];
    self.topController = taskWindowCOntroller;

    [super show];

    [taskWindowCOntroller prepareOnScreen:self.parentController];
    [taskWindowCOntroller show:self.parentController];
}

- (void)taskStarted:(const PEXTaskEvent *const)event {

}

- (void)taskEnded:(const PEXTaskEvent *const)event
{
    PEXGuiContactDetailsController * const controller = (PEXGuiContactDetailsController *) self.parentController;
    void (^completion)(void) = self.task.requestSuccess ?
            ^{ [controller loadCertificateAsync]; } :
            ^{ [controller showError]; };


    dispatch_sync(dispatch_get_main_queue(), ^(void) {
        [self dismissWithCompletion:completion];
    });
}

- (void)taskProgressed:(const PEXTaskEvent *const)event {

}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {

}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {

}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {

}


@end