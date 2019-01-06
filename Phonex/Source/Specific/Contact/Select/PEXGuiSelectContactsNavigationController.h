//
//  PEXGuiSelectContactsNavigationController.h
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiAppNavigationController.h"

#import "PEXContactSelectManager.h"
#import "PEXGrandSelectionManager.h"

@interface PEXGuiSelectContactsNavigationController : PEXGuiAppNavigationController<PEXContactSelectListener>

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title
                      manager: (PEXContactSelectManager * const) manager
                 grandManager: (PEXGrandSelectionManager * const) grandManager;

@end
