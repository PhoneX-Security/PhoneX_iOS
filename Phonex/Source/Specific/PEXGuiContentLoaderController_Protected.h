//
//  PEXGuiContentLoaderController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 22/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContentLoaderController.h"
#import "PEXGuiController_Protected.h"

@interface PEXGuiContentLoaderController ()
{
@protected
    volatile bool _cancel;
}

- (void) reloadContentAsync;

- (const UIView *) getContentView;
- (int) getItemsCount;
- (void) checkEmpty;
- (void) alignEmptyIndicator;

- (void) preload;
- (void) postload;
- (void) postloadIndicatorDismissed;

// in mutex
- (void) loadContent;
- (void) clearContent;

@end
