//
//  PEXGuiNoticeManager.h
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiDialogBinaryListener.h"

@interface PEXGuiNoticeManager : NSObject<PEXGuiDialogBinaryListener>

- (void) reshowNoticeIfNeeded;
- (void) showNotice: (const uint64_t) noticedVersionCode;
- (void) dismissNoticeFromOutside;
- (void) bringToFront;

+ (PEXGuiNoticeManager *) instance;

@end
