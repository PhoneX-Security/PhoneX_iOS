//
//  PEXGuiPresenceCenter.h
//  Phonex
//
//  Created by Matej Oravec on 01/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiPresence.h"
#import "PEXPbPush.pb.h"

@class PEXPresenceState;
@class PEXConnectivityChange;

@protocol PEXGuiPresenceListener

- (void) presencePreset: (const PEX_GUI_PRESENCE) presetPresence;
- (void) presenceSet: (const PEX_GUI_PRESENCE) setPresence;
- (void) presenceProcessing;

@end

@interface PEXGuiPresenceCenter : NSObject

- (void)addListenerAsync: (id<PEXGuiPresenceListener>) listener;
- (void) removeListener: (id<PEXGuiPresenceListener>) listener;

+ (PEXGuiPresenceCenter *) instance;
+ (PEX_GUI_PRESENCE) translatePresenceState: (const PEXPbPresencePushPEXPbStatus) pres;
+ (PEXPbPresencePushPEXPbStatus) translateToPresenceState: (const PEX_GUI_PRESENCE) pres;

- (PEX_GUI_PRESENCE) currentWantedPresence;
- (void)setCurrentWantedPresenceAsync: (const PEX_GUI_PRESENCE) presence;
- (void) presencePostSet: (PEXPresenceState *) state;

/**
* Presence center calls this method to inform us about new presence state.
* Called when update is not caused by user.
*/
- (void)presenceStateUpdated:(PEXPresenceState *)state;
- (void)onConnectivityChanged: (PEXConnectivityChange *) conChange;
@end
