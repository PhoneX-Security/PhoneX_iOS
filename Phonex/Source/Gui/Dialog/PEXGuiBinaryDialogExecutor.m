//
// Created by Matej Oravec on 17/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiBinaryDialogExecutor.h"

#import "PEXGuiUnaryDialogExecutor_Protected.h"

#import "PEXGuiFactory.h"

@interface PEXGuiBinaryDialogExecutor ()

@end

@implementation PEXGuiBinaryDialogExecutor {

}

- (void) showTopController
{
    if (self.attributedText!=nil){
        self.topController = [PEXGuiFactory showBinaryDialog:self.parentController.fullscreener
                                          withAttributedText:self.attributedText
                                                    listener:self
                                               primaryAction:self.primaryButtonText
                                             secondaryAction:self.secondaryButtonText];
    } else {
        self.topController = [PEXGuiFactory showBinaryDialog:self.parentController.fullscreener
                                                    withText:self.text
                                                    listener:self
                                               primaryAction:self.primaryButtonText
                                             secondaryAction:self.secondaryButtonText];
    }
}

- (void)secondaryButtonClicked {

    void (^action)(void) = self.secondaryAction;
    [self dismissWithCompletion:action];
}


@end