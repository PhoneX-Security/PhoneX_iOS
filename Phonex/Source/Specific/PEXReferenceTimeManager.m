//
// Created by Matej Oravec on 17/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXReferenceTimeManager.h"
#import "PEXService.h"
#import "PEXConnectivityChange.h"
#import "PEXTask.h"
#import "PEXLicenceCheckTask.h"
#import "hr.h"

@implementation PEXReferenceTime

- (id)copyWithZone:(NSZone *)zone {
    PEXReferenceTime *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.localInSeconds = self.localInSeconds;
        copy.serverTime = self.serverTime;
    }

    return copy;
}

- (BOOL)isEqual:(id)other {
    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToTime:other];
}

- (BOOL)isEqualToTime:(PEXReferenceTime *)time {
    if (self == time)
        return YES;
    if (time == nil)
        return NO;
    if (self.localInSeconds != time.localInSeconds)
        return NO;
    if (self.serverTime != time.serverTime && ![self.serverTime isEqualToDate:time.serverTime])
        return NO;
    return YES;
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.localInSeconds;
    hash = hash * 31u + [self.serverTime hash];
    return hash;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.localInSeconds = [coder decodeInt64ForKey:@"self.localInSeconds"];
        self.serverTime = [coder decodeObjectForKey:@"self.serverTime"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:self.localInSeconds forKey:@"self.localInSeconds"];
    [coder encodeObject:self.serverTime forKey:@"self.serverTime"];
}


@end

@interface PEXReferenceTimeManager ()
{
@private
    bool _isRegisteredForConnectionStatus;
}

// Reference time must be set on
// - login
// - after auto-login
// - on connection change if check on auto-login failed
@property (nonatomic) PEXReferenceTime * referenceTime;

@property (nonatomic) NSRecursiveLock * lock;
@property (nonatomic) NSMutableArray * listeners;

@end

@implementation PEXReferenceTimeManager {

}

- (id) init
{
    self = [super init];

    self.lock = [[NSRecursiveLock alloc] init];
    self.listeners = [[NSMutableArray alloc] init];
    _isRegisteredForConnectionStatus = false;

    return self;
}

- (PEXReferenceTime *) getReferenceTime
{
    return self.referenceTime;
}

- (PEXReferenceTime *) setReferenceServerTime: (NSDate *) referenceTime
{
    [self.lock lock];
    PEXReferenceTime * refTime = [self setReferenceServerTimeInternal:referenceTime];
    [self.lock unlock];

    [self notifyListeners:[self.listeners copy] refTime:[refTime copy]];
    return refTime;
}

- (PEXReferenceTime *) setReferenceServerTimeInternal: (NSDate *)referenceServerTime
{
    PEXReferenceTime * const result = [[PEXReferenceTime alloc] init];

    result.serverTime = referenceServerTime;
    result.localInSeconds = PEXGetPIDTimeInSeconds();

    self.referenceTime = result;
    return result;
}

- (void) addListener: (id<PEXReferenceTimeUpdateListener>) listener
{
    [self.lock lock];
    if (![self.listeners containsObject:listener]){
        [self.listeners addObject:listener];

    } else {
        DDLogWarn(@"Listener already added: %@", listener);

    }

    const PEXReferenceTime * const referenceTimeCopy = [self.referenceTime copy];
    [self.lock unlock];

    [listener added:referenceTimeCopy];
}

- (void) removeListener: (id<PEXReferenceTimeUpdateListener>) listener
{
    [self.lock lock];

    [self.listeners removeObject:listener];

    [self.lock unlock];
}

- (void)startCheckForTimeIfNeeded: (void (^)(void)) blockOnNoConnection
{
    if (self.referenceTime)
        return;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if (!self.referenceTime)
        {
            PEXLicenceCheckTask *const task = [[PEXLicenceCheckTask alloc] init];
            task.policyProcessingSync = NO;
            task.settingsProcessingSync = NO;
            task.accountSettingsProcessingSync = NO;
            task.shouldUpdateReferenceTime = NO; // We do it ourselves.

            PEXSOAPResult *soapResult;
            hr_accountInfoV1Response *const response =
                    [task requestUserInfo:[[PEXAppState instance] getPrivateData] cancelBlock:nil res:&soapResult];

            [self.lock lock];

            // whether the server time is available or not, we need to start delayed licence expiration notification.
            // if the time is available the started notification is cancelled.
            if (blockOnNoConnection)
                blockOnNoConnection();

            if (response && response.serverTime)
            {
                PEXReferenceTime * refTime = [self setReferenceServerTimeInternal:response.serverTime];
                [self notifyListeners:[self.listeners copy] refTime:[refTime copy]];
                [self unregisterForConnectionChanges];
            }
            else
            {
                [self registerForConnectionChanges];
            }

            [self.lock unlock];
        }

    });
}

- (void) registerForConnectionChanges
{
    if (!_isRegisteredForConnectionStatus)
    {
        _isRegisteredForConnectionStatus = true;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onConnectivityChangeNotification:)
                                                     name:PEX_ACTION_CONNECTIVITY_CHANGE
                                                   object:nil];

    }
}

- (void) unregisterForConnectionChanges
{
    if (_isRegisteredForConnectionStatus)
    {
        _isRegisteredForConnectionStatus = false;

        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)onConnectivityChangeNotification:(NSNotification *)notification
{
    if (!notification || ![PEX_ACTION_CONNECTIVITY_CHANGE isEqualToString:notification.name])
        return;

    const PEXConnectivityChange * const conChange = notification.userInfo[PEX_EXTRA_CONNECTIVITY_CHANGE];

    if (conChange &&
            (conChange.connection == PEX_CONN_GOES_UP))
    {
        [self startCheckForTimeIfNeeded: nil];
    }
}

- (void) notifyListeners {
    [self.lock lock];
    [self notifyListeners:[self.listeners copy] refTime:[self.referenceTime copy]];
    [self.lock unlock];
}

- (void) notifyListeners: (NSArray *) listeners refTime: (PEXReferenceTime *) refTime {
    if (listeners.count == 0) {
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (id <PEXReferenceTimeUpdateListener> listener in listeners) {
            [listener fill:refTime];
        }
    });
}

- (NSDate *) currentTimeSinceReference: (NSDate * const) dateIfServerNotAvavailable
{
    PEXReferenceTime *const referenceTime = [self.referenceTime copy];
    @try {
        // Reference time is not available
        if (referenceTime == nil) {
            return dateIfServerNotAvavailable;
        }

        const NSTimeInterval interval = PEXGetPIDTimeInSeconds() - referenceTime.localInSeconds;
        NSDate *const result = [referenceTime.serverTime dateByAddingTimeInterval:interval];
        return result;

    } @catch(NSException * e) {
        DDLogError(@"Exception in getting reference time %@", e);
    }

    return dateIfServerNotAvavailable;
}

- (void) dealloc
{
    [self.lock lock];

    [self unregisterForConnectionChanges];
    // wait for checking

    [self.lock unlock];
}

@end