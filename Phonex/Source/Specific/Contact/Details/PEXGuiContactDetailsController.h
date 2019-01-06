//
//  PEXGuiContactDetails.h
//  Phonex
//
//  Created by Matej Oravec on 12/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiControllerContentObserver.h"
#import "PEXTaskListener.h"

@class PEXDbContact;

@interface PEXGuiContactDetailsController : PEXGuiControllerContentObserver<PEXTaskListener>

- (void) loadCertificateAsync;
- (void) showError;

- (void) setNavigationParent: (PEXGuiNavigationController *) navigation;

- (id) initWithContact: (PEXDbContact * const) contact;

@end
