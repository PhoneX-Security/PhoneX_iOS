//
//  PEXGuiSelectVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileControllerVisitor.h"

#import "PEXFilePickManager.h"

@interface PEXGuiFileSelectVisitor : PEXGuiFileControllerVisitor<PEXFilePickListener>

- (id) initWithManager: (PEXFilePickManager * const) manager;

@end
