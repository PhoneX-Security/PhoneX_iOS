//
//  PEXGuiContactsSelectController.h
//  Phonex
//
//  Created by Matej Oravec on 18/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactsController.h"

#import "PEXContactSelectManager.h"

@interface PEXGuiContactsSelectController : PEXGuiContactsController<PEXContactSelectListener>

- (id) initWithManager: (PEXContactSelectManager * const) manager;

@end
