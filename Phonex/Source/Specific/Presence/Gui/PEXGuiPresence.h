//
//  PEXGuiPresence.h
//  Phonex
//
//  Created by Matej Oravec on 01/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef Phonex_PEXGuiPresence_h
#define Phonex_PEXGuiPresence_h

typedef enum
{
    PEX_GUI_PRESENCE_ONLINE = 0,
    PEX_GUI_PRESENCE_AWAY,
    PEX_GUI_PRESENCE_OFFLINE,
    PEX_GUI_PRESENCE_LAST = PEX_GUI_PRESENCE_OFFLINE,
    PEX_GUI_PRESENCE_FIRST = PEX_GUI_PRESENCE_ONLINE
} PEX_GUI_PRESENCE;

#endif
