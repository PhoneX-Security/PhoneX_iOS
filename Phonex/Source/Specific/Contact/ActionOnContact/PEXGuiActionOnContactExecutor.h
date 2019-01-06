//
//  PEXGuiActionOnContactExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiExecutor.h"

#import "PEXGuiActionOnContactListener.h"

@class PEXDbContact;
@class PEXGuiController;

@interface PEXGuiActionOnContactExecutor : PEXGuiExecutor<PEXGuiActionOnContactListener>

-(void) executeWithContact: (const PEXDbContact * const) contact
              parentController: (PEXGuiController * const) parentController;

@end
