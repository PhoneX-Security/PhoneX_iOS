//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXGuiTone;


@interface PEXGuiTonesController : PEXGuiController
@property(nonatomic) NSArray * toneList;
@property(nonatomic) NSString * prefKey;

- (PEXGuiTone *) getSelectedTone;
- (void) stopPlaying;
@end