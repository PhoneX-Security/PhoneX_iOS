//
//  PEXContactRemoveExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 07/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXTaskListener.h"

@class PEXGuiContactsController;
@class PEXDbContact;

@interface PEXContactRemoveExecutor : NSObject<PEXTaskListener>

- (id) initWithController: (PEXGuiContactsController *) contactsController
          contactToRemove: (const PEXDbContact * const) contact;

- (void) execute;

@end
