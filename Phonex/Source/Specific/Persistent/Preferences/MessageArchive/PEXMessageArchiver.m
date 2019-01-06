//
// Created by Matej Oravec on 31/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXMessageArchiver.h"
#import "PEXDbAppContentProvider.h"
#import "PEXDBMessage.h"
#import "PEXGuiTimeUtils.h"
#import "PEXDelayedTask.h"
#import "PEXDatabase.h"
#import "PEXTask_Protected.h"
#import "PEXMessageManager.h"

@interface PEXMessageArchiver ()
{
@private bool _isActive;
}
@property (nonatomic) const NSNumber *deletionTimeInSeconds;
@property (nonatomic) const NSNumber *deletionTimeInSecondsOnPause;

@property (nonatomic) const PEXDbMessage * oldestMessage;

@property (nonatomic) NSLock * lock;

@property (nonatomic) PEXDelayedTask * deletionTask;

@end

@implementation PEXMessageArchiver {

}

- (id) init
{
    self = [super init];

    self.lock = [[NSLock alloc] init];

    return self;
}

+ (PEXMessageArchiver *) instance
{
    static PEXMessageArchiver * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXMessageArchiver alloc] init];
    });

    return instance;
}

- (void) stop
{
    [self setTimerInSeconds:nil];
}

- (void) pause
{
    self.deletionTimeInSecondsOnPause = self.deletionTimeInSeconds;
    [self stop];
}


- (void) resume
{
    [self setTimerInSeconds:self.deletionTimeInSecondsOnPause];
}

// first method executed EVER!
- (void)setTimerInSeconds: (const NSNumber * const)timeInSeconds
{
    [self.lock lock];

    // on/change or off
    if (timeInSeconds)
    {
        self.deletionTimeInSeconds = timeInSeconds;
        [self deleteAndReset];

        if (!_isActive)
        {
            _isActive = true;
            [[PEXDbAppContentProvider instance] registerObserverInsert:self];
            [[PEXDbAppContentProvider instance] registerObserverDelete:self];
        }
    }
    else
    {
        if (_isActive)
        {
            [[PEXDbAppContentProvider instance] unregisterObserverInsert:self];
            [[PEXDbAppContentProvider instance] unregisterObserverDelete:self];
            _isActive = false;
        }

        [self applyOldestMessage:nil];
        self.deletionTimeInSeconds = nil;
    }

    [self.lock unlock];
}

- (bool) deliverSelfNotifications{return true;}

- (void)dispatchChange:(const bool)selfChange uri:(const PEXUri *const)uri {

}


- (void) dispatchChangeInsert: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbMessage getURI]])
        return;

    [self changeOnMessages];
}

- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbMessage getURI]])
        return;

    [self changeOnMessages];
}

- (void)changeOnMessages
{
    [self.lock lock];

    const PEXDbMessage * const oldestMessage = [PEXMessageArchiver getOldestMessage];

    if ((oldestMessage != self.oldestMessage) &&
            ((oldestMessage && ![oldestMessage isEqualToMessage:self.oldestMessage]) ||
                    (self.oldestMessage && ![self.oldestMessage isEqualToMessage:oldestMessage])))
    {
        [self applyOldestMessage:oldestMessage];
    }

    [self.lock unlock];
}

- (void) deleteAndReset
{
    [PEXMessageManager removeAllOlderThan:self.deletionTimeInSeconds.longLongValue];

    [self applyOldestMessage:[PEXMessageArchiver getOldestMessage]];
}

- (void) applyOldestMessage: (const PEXDbMessage * const)oldestMessage
{
    // cancel previous task if we are just changing the time of the time
    if (self.deletionTask && ![self.deletionTask isCancelled])
    {
        [self.deletionTask cancel];
        // DO NOT NIL-OUT THE reference.
        // the may may be stil doing something after cancel (cleanup)
    }

    self.oldestMessage = oldestMessage;

    if (self.oldestMessage)
    {
        NSDate * const eventDate = [self.oldestMessage.date
                dateByAddingTimeInterval:self.deletionTimeInSeconds.longLongValue];

        const dispatch_time_t timeDelayInMilliseconds = [PEXDateUtils getIntervalUntilDate:eventDate];

        // TASK CREATION
        self.deletionTask = [[PEXDelayedTask alloc] initWithEventTime:timeDelayInMilliseconds];

        WEAKSELF;
        self.deletionTask.completionBlock = ^{
            [weakSelf.lock lock];
            [weakSelf deleteAndReset];
            [weakSelf.lock unlock];
        };

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf.deletionTask start];
        });
    }
}

+ (const PEXDbMessage *) getOldestMessage
{
    PEXDbCursor * const cursor = [[PEXDbAppContentProvider instance]
            query:[PEXDbMessage getURI]
       projection:[PEXDbMessage getOldestMessageFullProjection]
        selection:nil
    selectionArgs:nil
        sortOrder:nil];

    const PEXDbMessage * result;
    if (cursor && [cursor moveToNext])
    {
            const PEXDbMessage * const m = [PEXDbMessage messageFromCursor:cursor];
            if (m.id)
                result = m;
    }

    return result;
}

@end