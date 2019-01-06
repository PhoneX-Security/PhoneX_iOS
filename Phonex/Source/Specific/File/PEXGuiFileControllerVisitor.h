//
//  PEXGuiFileControllerVisitor.h
//  Phonex
//
//  Created by Matej Oravec on 12/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiFileView.h"
#import "PEXGuiFileController.h"

// protocol?

@class PEXGuiFileController;

@interface PEXGuiFileControllerVisitor : NSObject

@property (nonatomic, weak) PEXGuiFileController * controller;

- (void) postLoad;
- (void) onDismiss;
- (void) specifyFileView: (PEXGuiFileView * const) fileView
                withData: (const PEXFileData * const) data;

@end
