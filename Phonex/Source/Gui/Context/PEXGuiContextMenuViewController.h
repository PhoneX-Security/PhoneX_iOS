//
//  PEXGuiContextMenuViewController.h
//  Phonex
//
//  Created by Matej Oravec on 05/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiController.h"

#import "PEXRefDictionary.h"

@interface PEXGuiContextMenuViewController : PEXGuiController

- (id) initWithActionsAndPresentations: (PEXRefDictionary * const) actionsAndPresentations;

@end
