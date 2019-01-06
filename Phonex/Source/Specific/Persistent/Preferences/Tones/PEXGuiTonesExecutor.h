//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiExecutor.h"


@interface PEXGuiTonesExecutor : PEXGuiExecutor<PEXGuiDialogBinaryListener>
- (id) initWithParentController: (PEXGuiController * const) parent
                       toneList: (NSArray*) toneList
                        prefKey: (NSString *) prefKey;
@end