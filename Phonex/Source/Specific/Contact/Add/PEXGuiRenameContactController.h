//
// Created by Matej Oravec on 05/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiBusyInputFullscreenController.h"
#import "PEXTaskListener.h"


@interface PEXGuiRenameContactController : PEXGuiBusyInputFullscreenController<PEXTaskListener>

@property (nonatomic) NSString * contactsUsername;
@property (nonatomic) NSString * contactsOldAlias;

@property (nonatomic) NSAttributedString * descriptionIntroe;

+ (void) showRenameControllerWithUsername: (NSString * const) username
                                    alias: (NSString * const) alias
                                forParent: (PEXGuiController * const) parent;

@end