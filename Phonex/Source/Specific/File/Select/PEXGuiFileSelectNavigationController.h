//
//  PEXGuiFilesNavigationController.h
//  Phonex
//
//  Created by Matej Oravec on 05/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileNavigationController.h"

#import "PEXFilePickManager.h"
#import "PEXGrandSelectionManager.h"

#import "PEXGuiDialogBinaryListener.h"

@interface PEXGuiFileSelectNavigationController : PEXGuiFileNavigationController<PEXFilePickListener, PEXGuiDialogBinaryListener>

- (id) initWithViewTitle: (NSString * const) title
           selectWithContacts: (const bool) withContacts
                 grandManager: (PEXGrandSelectionManager *) grandManager;

@end
