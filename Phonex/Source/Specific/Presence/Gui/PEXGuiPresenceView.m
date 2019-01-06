//
//  PEXGuiPresenceView.m
//  Phonex
//
//  Created by Matej Oravec on 28/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiPresenceView.h"

#import "PEXGuiPresence.h"
#import "PEXGuiPresenceCenter.h"

@implementation PEXGuiPresenceView

- (void) setPresence: (const PEXPbPresencePushPEXPbStatus) status
{
    PEX_GUI_PRESENCE presence = [PEXGuiPresenceCenter translatePresenceState:status];
    [self setStatus:presence];
}

- (void) setStatus: (const PEX_GUI_PRESENCE) presence
{
    switch (presence)
    {
        case PEX_GUI_PRESENCE_ONLINE: self.backgroundColor = PEXCol(@"green_normal"); break;
        case PEX_GUI_PRESENCE_OFFLINE: self.backgroundColor = PEXCol(@"light_gray_low"); break;
        case PEX_GUI_PRESENCE_AWAY: self.backgroundColor = PEXCol(@"red_normal"); break;
    }
}

@end    
