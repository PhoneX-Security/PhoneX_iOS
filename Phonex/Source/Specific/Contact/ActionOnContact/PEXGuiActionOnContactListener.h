//
//  PEXGuiActionOnContactListener.h
//  Phonex
//
//  Created by Matej Oravec on 23/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#ifndef Phonex_PEXGuiActionOnContactListener_h
#define Phonex_PEXGuiActionOnContactListener_h

@protocol PEXGuiActionOnContactListener <NSObject>

- (void) callClicked;
- (void) messageClicked;
- (void) fileClicked;
- (void) settingsClicked;

@end

#endif
