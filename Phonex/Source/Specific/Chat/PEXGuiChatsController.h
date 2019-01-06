//
//  PEXGuiMessagesController.h
//  Phonex
//
//  Created by Matej Oravec on 02/10/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiControllerContentObserver.h"

@protocol PEXContentObserver;
@class PEXGuiChat;
@class PEXDbContact;

@interface PEXGuiChatsController : PEXGuiContentLoaderController <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) PEXChatsManager * manager;

- (void)updateItemsForIndexPaths: (NSArray * const) indexPaths;
- (void)removeItemsForIndexPaths: (NSArray * const) indexPat;
- (void)addItemsForIndexPaths: (NSArray * const) indexPaths;

- (void)moveItemFrom:(NSIndexPath *const)from to:(NSIndexPath *const)to;

- (void) largeUpdate;

@end
