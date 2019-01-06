//
// Created by Dusan Klinec on 29.01.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import "PEXGuiRecoveryEmailExecutor.h"
#import "PEXAccountSettingsTask.h"
#import "PEXMuteNotificationUpdateExecutor.h"
#import "PEXGuiProgressController.h"
#import "PEXDBUserProfile.h"
#import "PEXGuiWindowController.h"
#import "PEXGuiProgressController_Protected.h"
#import "PEXGuiRecoveryEmailController.h"
#import "PEXGuiFactory.h"
#import "PEXUtils.h"
#import "PEXService.h"
#import "PEXSOAPResult.h"
#import "PEXDBUserProfile.h"
#import "PEXDbAppContentProvider.h"

@interface PEXGuiRecoveryEmailExecutor ()

@property (nonatomic) PEXGuiController * parent;

@property (nonatomic) PEXGuiProgressController * progress;

@end

@implementation PEXGuiRecoveryEmailExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;

    return self;
}

- (void) show
{
    self.progress = [[PEXGuiProgressController alloc] init];
    self.progress.showProgressBar = false;

    PEXGuiWindowController * const taskWindowController =
            [[PEXGuiWindowController alloc] initWithViewController:self.progress];

    [self.progress setShowProgressBar:NO];
    [self.progress showTaskStarted:nil];
    self.topController = taskWindowController;

    [super show];

    [taskWindowController prepareOnScreen:self.parentController];
    [taskWindowController show:self.parentController];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self.parent viewDidReveal];
    [super dismissWithCompletion:completion];
}

@end
