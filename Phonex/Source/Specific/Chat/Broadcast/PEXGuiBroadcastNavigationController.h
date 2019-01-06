//
//  PEXGuiBroadcastNavigationControllerViewController.h
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiAppNavigationController.h"

#import "PEXGrandSelectionManager.h"

@class PEXGuiMessageComposerController;

@interface PEXGuiBroadcastNavigationController :
    PEXGuiAppNavigationController<PEXGrandListener>

- (id) initWithViewController: (PEXGuiController * const) controller
           composerController: (PEXGuiMessageComposerController * const) composerController
                 grandManager: (PEXGrandSelectionManager * const) grandManager;

@end
