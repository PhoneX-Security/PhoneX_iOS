//
//  PEXGuiCallsController.h
//  Phonex
//
//  Created by Matej Oravec on 08/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiControllerContentObserver.h"

#import "PEXGuiDialogBinaryListener.h"

@class PEXGuiCallLog;
@class PEXCallsManager;
@class PEXDbCallLog;
@class PEXDbContact;

@interface PEXGuiCallsController : PEXGuiContentLoaderController<PEXGuiDialogBinaryListener, UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) PEXCallsManager * manager;

- (void) updateCallLogsForIndexPaths: (NSArray * const) indexPaths;
- (void) removeCallLogsForIndexPaths: (NSArray * const) indexPat;
- (void) addCallLogsForIndexPaths: (NSArray * const) indexPaths;
- (void) largeUpdate;

@end
