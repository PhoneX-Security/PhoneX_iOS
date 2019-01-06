//
// Created by Matej Oravec on 17/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileController.h"


@interface PEXGuiFileBySelection : PEXGuiFileController


- (id) initWithVisitor: (PEXGuiFileControllerVisitor * const) visitor
      preselectedFiles: (NSArray * const) preselectedFiles;

@end