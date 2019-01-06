//
//  PEXGuiChatController.h
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerContentObserver.h"
#import "PEXGuiPreviewExecutor.h"
#import "PEXLicenceManager.h"
#import "PEXChatAccountingManager.h"

@class PEXGuiChat;
@class PEXDbContact;

@interface PEXGuiChatController : PEXGuiControllerContentObserver
        <PEXGuiPreviewDelegate,
        UICollectionViewDelegateFlowLayout,
        UICollectionViewDataSource,

        PEXMessageAccountingListener>

+ (void) showChatInNavigation:(PEXGuiController * const) parent
                  withContact:(const PEXDbContact * const)contact;
- (id) initWithContact: (const PEXDbContact * const)contact;

@end
