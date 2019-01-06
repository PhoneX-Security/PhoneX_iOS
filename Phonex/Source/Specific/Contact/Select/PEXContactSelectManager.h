//
//  PEXGuiContactSelectManager.h
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXDbContact.h"

@protocol PEXContactSelectListener

- (void) contactAdded: (const PEXDbContact * const) contact;
- (void) contactRemoved: (const PEXDbContact * const) contact;
- (void) clearSelection;
- (void) fillIn: (NSArray * const) selectedContacts;

@end

@interface PEXContactSelectManager : NSObject

- (NSArray *) getSelected;
- (NSUInteger) getSelectedCount;
- (void) addContact: (const PEXDbContact * const) contact;
- (void) removeContact: (const PEXDbContact * const) contact;
- (void) addListener: (id<PEXContactSelectListener>) listener;
- (void) deleteListener: (id<PEXContactSelectListener>) listener;
- (void) clearSelection;

@end
