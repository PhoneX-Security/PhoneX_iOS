//
//  PEXFilePickManager.h
//  Phonex
//
//  Created by Matej Oravec on 05/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXFileData.h"

@protocol PEXFilePickListener

- (void) fileAdded: (const PEXFileData * const) asset at: (const NSUInteger) position;
- (void) fileRemoved: (const PEXFileData * const) asset at: (const NSUInteger) position;

- (void)notifyOverlapError;
- (void) clearSelection;

- (void) fillIn: (NSArray * const) files;

@end

@interface PEXFilePickManager : NSObject

@property (nonatomic, readonly) NSArray * restrictorResults;

- (bool) notifyErrorIfOverlaps;

- (NSArray *) getSelectedFiles;
- (NSUInteger) getSelectedFilesCount;

- (void) addFile: (const PEXFileData * const) asset;
- (void) removeFile: (const PEXFileData * const) asset;
- (void) addListener: (id<PEXFilePickListener>) listener;
- (void) deleteListener: (id<PEXFilePickListener>) listener;
- (void) clearSelection;

- (void) restrictiorChanged;

@end
