//
//  PEXGuiFileController.h
//  Phonex
//
//  Created by Matej Oravec on 21/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContentLoaderController.h"

#import "PEXGuiFileControllerVisitor.h"

@class PEXGuiFileControllerVisitor;

@interface PEXGuiFileController : PEXGuiContentLoaderController<UICollectionViewDelegate, UICollectionViewDataSource>

- (id) initWithVisitor: (PEXGuiFileControllerVisitor * const) visitor;

- (void)selectionChanged;
- (void)datasetChanged;

- (void)dataLoadStarted;
- (void)dataLoadFinished;

@end

@interface PEXGuiItemHelper : NSObject

@property (nonatomic) NSDate * date;
@property (nonatomic) NSURL * url;

@end