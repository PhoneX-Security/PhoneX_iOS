//
// Created by Matej Oravec on 22/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXAssetLibraryManager.h"
#import "PEXDelayedTask.h"

static const int64_t LIBRARY_KEEP_ALIVE_SECONDS = 5LL;
static const useconds_t BEFORE_INSTANCE_INIT = 50000;

@interface PEXAssetLibraryManager() {

    volatile int _assteLibraryAccessorsCount;

}

@property (nonatomic) NSLock * libraryInstanceLock;
@property (nonatomic) NSLock * taskLock;

@property (nonatomic) ALAssetsLibrary * activeAssetLibrary;
@property (nonatomic) PEXDelayedTask *releaseTask;

@property (nonatomic) dispatch_semaphore_t semaphore;

@end;

@implementation PEXAssetLibraryManager {

}

- (void) increment
{
    [self.taskLock lock];
    ++_assteLibraryAccessorsCount;
    DDLogVerbose(@"ASSETSLIBRARY ACCESS INCREMENT at %d", _assteLibraryAccessorsCount);
    [self.taskLock unlock];
}

-(void) releaseAssetLibrary
{
    [self.taskLock lock];

    [self decrementInternal];

    [self.libraryInstanceLock unlock];
    dispatch_semaphore_signal(self.semaphore);

    [self.taskLock unlock];
}

-(ALAssetsLibrary *) getAssetLibrary
{
    ALAssetsLibrary * result;

    [self.taskLock lock];

    ++_assteLibraryAccessorsCount;

    while (![self.libraryInstanceLock tryLock])
    {
        [self.taskLock unlock];
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        [self.taskLock lock];
    }

    if (self.activeAssetLibrary == nil)
    {
        usleep(BEFORE_INSTANCE_INIT); /* wait 0.05 sec and try the lock again*/
        DDLogVerbose(@"ASSETSLIBRARY INSTANCE INIT at %d", _assteLibraryAccessorsCount);
        self.activeAssetLibrary = [[ALAssetsLibrary alloc] init];
    }

    DDLogVerbose(@"ASSETSLIBRARY INSTANCE RETURN at %d", _assteLibraryAccessorsCount);

    result = self.activeAssetLibrary;

    [self.taskLock unlock];

    return result;
}

- (void) decrement
{
    [self.taskLock lock];
    [self decrementInternal];
    [self.taskLock unlock];
}

- (void) decrementInternal
{
    --_assteLibraryAccessorsCount;
    DDLogVerbose(@"ASSETSLIBRARY ACCESS DECREMENT at %d", _assteLibraryAccessorsCount);
    if (((_assteLibraryAccessorsCount) == 0) && (self.releaseTask == nil))
    {
        [self setReleaseTask];
    }
}

- (int) getAssteLibraryAccessorsCount{
    return _assteLibraryAccessorsCount;
}

- (void) setReleaseTask
{
    DDLogVerbose(@"ASSETSLIBRARY RELEASE TASK INIT at %d", _assteLibraryAccessorsCount);
    const dispatch_time_t timeDelayInMilliseconds =
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(LIBRARY_KEEP_ALIVE_SECONDS * NSEC_PER_SEC));

    // TASK CREATION
    self.releaseTask = [[PEXDelayedTask alloc] initWithEventTime:timeDelayInMilliseconds];

    WEAKSELF;
    self.releaseTask.completionBlock = ^{
        PEXAssetLibraryManager * sSelf = weakSelf;
        
        [sSelf.taskLock lock];
        const int accessors = [sSelf getAssteLibraryAccessorsCount];

        DDLogVerbose(@"ASSETSLIBRARY RELEASE 5 SECONDS ARE UP at %d", accessors);
        if ((accessors) == 0)
        {
            DDLogVerbose(@"ASSETSLIBRARY RELEASE TASK !!!!!!!!!! at %d", accessors);
            sSelf.activeAssetLibrary = nil;
        }

        sSelf.releaseTask = nil;
        [sSelf.taskLock unlock];
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf.releaseTask start];
    });
}

- (id) init
{
    self = [super init];

    _assteLibraryAccessorsCount = 0;
    self.libraryInstanceLock = [[NSLock alloc] init];
    self.taskLock = [[NSLock alloc] init];
    self.semaphore = dispatch_semaphore_create(0);

    return self;
}

+ (PEXAssetLibraryManager *) instance
{
    static PEXAssetLibraryManager * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXAssetLibraryManager alloc] init];
    });

    return instance;
}

@end