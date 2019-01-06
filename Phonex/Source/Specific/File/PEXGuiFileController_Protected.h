//
//  PEXGuiFileController_Protected.h
//  Phonex
//
//  Created by Matej Oravec on 11/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileController.h"
#import "PEXGuiContentLoaderController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXRefDictionary.h"
#import "PEXGuiMenuItemView.h"

#import "PEXGuiFileUtils.h"

#import "PEXFileData.h"
#import "PEXGuiFileView.h"

@interface PEXGuiFileController ()
{
@protected
    volatile bool _finished;
}

- (void) addFileView: (const PEXFileData * const) data;

- (void)addFileHelper: (const PEXGuiItemHelper * const) fileHelper;

- (void) tweakView: (PEXGuiFileView * const) data;

@end
