//
//  PEXassetPickManager.m
//  Phonex
//
//  Created by Matej Oravec on 05/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXFilePickManager.h"
#import "PEXFileSelectRestrictor.h"
#import "PEXFileRestrictorManager.h"
#import "PEXLicenceManager.h"
#import "PEXService.h"

@interface PEXFilePickManager ()
{
@private
    bool _somethingOverlaps;
}

@property (nonatomic) NSMutableArray * listeners;
@property (nonatomic) NSMutableArray * selectedFiles;
@property (nonatomic) NSLock * lock;

@property (nonatomic) PEXFileRestrictorManager * restrictorManager;

@end

@implementation PEXFilePickManager

- (bool) notifyErrorIfOverlaps
{
    if (_somethingOverlaps)
    {
        for (id<PEXFilePickListener> listener in self.listeners)
            [listener notifyOverlapError];
    }

    return _somethingOverlaps;
}

- (id) init
{
    self = [super init];

    _somethingOverlaps = true;
    self.listeners = [[NSMutableArray alloc] init];
    self.selectedFiles = [[NSMutableArray alloc] init];
    self.lock = [[NSLock alloc] init];
    self.restrictorManager = [[[[PEXService instance] licenceManager] fileRestrictorFactory] createManagerInstance];
    self.restrictorManager.pickManager = self;

    return self;
}

- (void) dealloc
{
    [[[[PEXService instance] licenceManager] fileRestrictorFactory] destroyManagerInstance:self.restrictorManager];
}

- (NSArray *) getSelectedFiles
{
    return self.selectedFiles;
}

- (NSUInteger) getSelectedFilesCount
{
    return self.selectedFiles.count;
}

- (void) addListener: (id<PEXFilePickListener>) listener
{
    [self.lock lock];

    [self.listeners addObject:listener];
    [listener fillIn:self.selectedFiles];

    [self.lock unlock];
}

- (void) deleteListener: (id<PEXFilePickListener>) listener
{
    [self.lock lock];

    [self.listeners removeObject:listener];

    [self.lock unlock];
}

- (void) clearSelection
{
    [self.lock lock];

    [self.selectedFiles removeAllObjects];
    [self notifyRestrictors];

    for (id<PEXFilePickListener> listener in self.listeners)
        [listener clearSelection];


    [self.lock unlock];
}

- (void) addFile: (const PEXFileData * const) asset
{
    [self.lock lock];
    @try {
        const NSUInteger newItemIdx = self.selectedFiles.count;
        [self.selectedFiles addObject:asset];
        [self notifyRestrictors];

        for (id <PEXFilePickListener> listener in self.listeners) {
            [listener fileAdded:asset at:newItemIdx];
        }
    }@catch (NSException *e){
        DDLogError(@"Exception adding file to selection: %@", e);

    }@finally {
        [self.lock unlock];
    }
}

- (void) removeFile: (const PEXFileData * const) asset
{
    [self.lock lock];

    const NSUInteger position = [self.selectedFiles indexOfObject:asset];
    if (position != NSNotFound)
    {
        [self.selectedFiles removeObjectAtIndex:position];
        [self notifyRestrictors];

        for (id<PEXFilePickListener> listener in self.listeners) {
            [listener fileRemoved:asset at:position];
        }
    }

    [self.lock unlock];
}

- (void) notifyRestrictors
{
    [self.restrictorManager setFiles:self.selectedFiles];
    _somethingOverlaps = ![self.restrictorManager everythingIsOk];
}

- (void) restrictiorChanged
{
    [self.lock lock];

    for (id<PEXFilePickListener> listener in self.listeners)
    {
        // just re-notice
        [listener fillIn:self.selectedFiles];
    }

    [self.lock unlock];
}

- (NSArray *) restrictorResults
{
    return [self.restrictorManager getRestrictorsDescriptions];
}

@end
