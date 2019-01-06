//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"

@interface PEXMuteNotificationExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener>
- (id) initWithParentController: (PEXGuiController * const) parent prefKey:(NSString *) prefKey;
@end