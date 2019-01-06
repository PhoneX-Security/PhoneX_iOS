//
// Created by Matej Oravec on 01/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiUnaryDialogExecutor.h"

#import "PEXGuiUnaryDialogExecutor_Protected.h"
#import "PEXGuiFactory.h"

@implementation PEXGuiUnaryDialogExecutor {

}

- (id) initWithController: (PEXGuiController * const) parentController
{
    self = [super init];

    self.parentController = parentController;

    return self;
}

- (void) show
{
    [self showTopController];
    [super show];
}

- (void) showTopController
{
    if (self.attributedText != nil){
        self.topController = [PEXGuiFactory showUnaryDialog:self.parentController.fullscreener
                                         withAttributedText:self.attributedText
                                                   listener:self
                                              primaryAction:self.primaryButtonText];
    } else {
        self.topController = [PEXGuiFactory showUnaryDialog:self.parentController.fullscreener
                                                   withText:self.text
                                                   listener:self
                                              primaryAction:self.primaryButtonText];
    }
}


- (void)primaryButtonClicked
{
    void (^action)(void) = self.primaryAction;

    [self dismissWithCompletion:action];
}

@end