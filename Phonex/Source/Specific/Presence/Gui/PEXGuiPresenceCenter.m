//
//  PEXGuiPresenceCenter.m
//  Phonex
//
//  Created by Matej Oravec on 01/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiPresenceCenter.h"
#import "PEXService.h"
#import "PEXPresenceCenter.h"
#import "PEXPresenceUpdateMsg.h"
#import "PEXUserPrivate.h"
#import "PEXPresenceState.h"
#import "PEXConnectivityChange.h"
#import "PEXUtils.h"

@interface PEXGuiPresenceCenter ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) NSMutableArray * listeners;
@property (nonatomic) BOOL wasConnectionWorkingLastTime;
@property (nonatomic) BOOL indicatingConnectionFailure;
@property (nonatomic) PEX_GUI_PRESENCE curPresence;
@end

@implementation PEXGuiPresenceCenter

- (PEX_GUI_PRESENCE) currentWantedPresence
{
    return [[PEXUserAppPreferences instance] getGuiWantedPresence];
}

+ (PEX_GUI_PRESENCE)translatePresenceState:(const PEXPbPresencePushPEXPbStatus)pres {
    PEX_GUI_PRESENCE presence = PEX_GUI_PRESENCE_OFFLINE;
    switch (pres)
    {
        default:
        case PEXPbPresencePushPEXPbStatusOffline:
            presence = PEX_GUI_PRESENCE_OFFLINE;
            break;

        case PEXPbPresencePushPEXPbStatusOnline:
            presence = PEX_GUI_PRESENCE_ONLINE;
            break;
        case PEXPbPresencePushPEXPbStatusBusy:
        case PEXPbPresencePushPEXPbStatusAway:
        case PEXPbPresencePushPEXPbStatusDnd:
        case PEXPbPresencePushPEXPbStatusCustom:
        case PEXPbPresencePushPEXPbStatusOncall:
        case PEXPbPresencePushPEXPbStatusDevsleep:
            presence = PEX_GUI_PRESENCE_AWAY;
            break;
    }

    return presence;
}

+ (PEXPbPresencePushPEXPbStatus)translateToPresenceState:(const PEX_GUI_PRESENCE)pres {
    PEXPbPresencePushPEXPbStatus presence = PEXPbPresencePushPEXPbStatusOffline;
    switch (pres)
    {
        default:
        case PEX_GUI_PRESENCE_OFFLINE:
            presence = PEXPbPresencePushPEXPbStatusOffline;
            break;

        case PEX_GUI_PRESENCE_ONLINE:
            presence = PEXPbPresencePushPEXPbStatusOnline;
            break;

        case PEX_GUI_PRESENCE_AWAY:
            presence = PEXPbPresencePushPEXPbStatusAway;
            break;
    }

    return presence;
}

- (void)setCurrentWantedPresenceAsync: (const PEX_GUI_PRESENCE) presence
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];

        NSArray * listenersCopy;
        if ([[PEXUserAppPreferences instance] getGuiWantedPresence] != presence || self.curPresence != presence) {
            [[PEXUserAppPreferences instance] setGuiWantedPresence:presence];
            self.curPresence = self.curPresence;
            listenersCopy = [self.listeners copy];
        }

        [self.lock unlock];

        if (listenersCopy)
        {
            for (id <PEXGuiPresenceListener> listener in listenersCopy)
                [listener presencePreset:presence];

            // Set presence to presence center.
            PEXService *svc = [PEXService instance];
            if ([PEXUtils isEmpty: svc.privData.username]){
                DDLogError(@"Empty user name in priv data %p", svc.privData);
            }

            PEXPresenceUpdateMsg *msg = [PEXPresenceUpdateMsg msgWithUser:svc.privData.username];
            msg.statusId = @([PEXGuiPresenceCenter translateToPresenceState:presence]);
            msg.updateKey = @"gui";
            [svc.presenceCenter setStateFromGui:msg];
        }

    });
}

- (void) setCurrentPresence: (const PEX_GUI_PRESENCE) presence
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *listenersCopy;
        [self.lock lock];
        if (self.curPresence != presence) {
            self.curPresence = presence;
            listenersCopy = [self.listeners copy];
        }
        [self.lock unlock];

        if (listenersCopy)
            for (id <PEXGuiPresenceListener> listener in listenersCopy)
                [listener presencePreset:presence];
    });
}

- (void) setPresenceProcessing
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        NSArray *const listenersCopy = [self.listeners copy];
        [self.lock unlock];

        for (id <PEXGuiPresenceListener> listener in listenersCopy)
            [listener presenceProcessing];
    });
}

- (void) presencePostSet: (PEXPresenceState *) state
{
    DDLogVerbose(@"Presence post set. Set was successful, state=%@", state);
    if (state != nil && state.lastUpdate != nil && ![@"gui" isEqualToString:state.lastUpdate.updateKey]){
        // This update is not from GUI. Ignore it.
        DDLogVerbose(@"Ignore this update, not from GUI");
        return;
    }

    [self presencePostSetStored];
}

/**
* Triggers set of post stored presence.
* Called by presence center when stack manages to set presence defined by user
* or by stack on successful SIP registration.
*/
-(void) presencePostSetStored {

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        NSArray *const listenersCopy = [self.listeners copy];
        const PEX_GUI_PRESENCE wantedPresence = [[PEXUserAppPreferences instance] getGuiWantedPresence];
        [self.lock unlock];

        for (id <PEXGuiPresenceListener> listener in listenersCopy)
            [listener presenceSet:wantedPresence];
    });
}

-(void) onConnectivityChanged: (PEXConnectivityChange *) conChange{
    BOOL works = [conChange isWholeSystemConnected];
    if (works == self.wasConnectionWorkingLastTime){
        return; // no change
    }

    self.wasConnectionWorkingLastTime = works;

    // If there is a change s.t. some state changed (done) and both are on -> restore OK state.
    if (works){
        // Restore normal state.
        DDLogVerbose(@"Restoring normal state - both registered OK");
        self.indicatingConnectionFailure = NO;
        [self presencePostSetStored];
    } else {
        // If there is a change s.t. some state changed (done) and there is at least one which is disconnected -> report bad connection.
        // Show progress circle.
        DDLogVerbose(@"Temporary offline state - some connection disconnected");
        self.indicatingConnectionFailure = YES;
        [self setPresenceProcessing];
    }
}

- (void)presenceStateUpdated:(PEXPresenceState *)state {
    DDLogVerbose(@"PresenceUpdate by stack: %@", state);
}

- (void)addListenerAsync: (id<PEXGuiPresenceListener>) listener
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.lock lock];
        [self.listeners addObject:listener];
        [self.lock unlock];

        if (self.indicatingConnectionFailure)
            [listener presenceProcessing];
    });
}

- (void) removeListener: (id<PEXGuiPresenceListener>) listener
{
    [self.lock lock];
    [self.listeners removeObject:listener];
    [self.lock unlock];
}


+ (PEXGuiPresenceCenter *) instance
{
    static PEXGuiPresenceCenter * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiPresenceCenter alloc] init];
    });

    return instance;
}

- (id) init
{
    self = [super init];

    self.lock = [[NSLock alloc] init];
    self.listeners = [[NSMutableArray alloc] init];
    self.wasConnectionWorkingLastTime = NO;
    self.indicatingConnectionFailure = YES;
    self.curPresence = [[PEXUserAppPreferences instance] getGuiWantedPresence];

    return self;
}

@end
