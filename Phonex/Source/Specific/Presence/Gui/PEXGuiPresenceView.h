//
//  PEXGuiPresenceView.h
//  Phonex
//
//  Created by Matej Oravec on 28/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCircleView.h"

#import "PEXPbPush.pb.h"
#import "PEXGuiPresence.h"

@interface PEXGuiPresenceView : PEXGuiCircleView


- (void) setPresence: (const PEXPbPresencePushPEXPbStatus) presence;
- (void) setStatus: (const PEX_GUI_PRESENCE) presence;

@end
