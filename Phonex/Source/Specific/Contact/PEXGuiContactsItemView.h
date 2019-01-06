//
//  PEXGuiContactsItemView.h
//  Phonex
//
//  Created by Matej Oravec on 22/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiMenuItemView.h"
#import "PEXGuiCircleView.h"
#import "PEXGuiPresenceView.h"

@class PEXDbContact;
@class PEXGuiRowItemViewWithImage;

#import "PEXGuiStaticDimmer.h"

@interface PEXGuiContactsItemView : PEXGuiRowItemView<UIGestureRecognizerDelegate, PEXGuiStaticDimmer>

- (void) initGui;
- (void) applyContact:  (const PEXDbContact * const) contact;
- (void) setShowUsername: (const bool) showUsername;

+ (bool) contact: (const PEXDbContact * const) c1
     needsUpdate: (const PEXDbContact * const) c2;
+ (void) copyContactFrom: (const PEXDbContact * const) c1
                     to: (PEXDbContact * const) c2;

@end
