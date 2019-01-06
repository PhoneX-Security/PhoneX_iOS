//
//  PEXGuiSelectVisitor.m
//  Phonex
//
//  Created by Matej Oravec on 24/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileSelectVisitor.h"
#import "PEXGuiFileSelectVisitor_Protected.h"
#import "PEXReport.h"

@interface PEXGuiFileSelectVisitor ()

@property (nonatomic) PEXFilePickManager * manager;

@end

@implementation PEXGuiFileSelectVisitor

- (void) specifyFileView: (PEXGuiFileView * const) fileView
                withData: (const PEXFileData * const) data;
{
    [[fileView getCheckView] addActionBlock:^{
        [PEXReport logUsrButton:PEX_EVENT_BTN_FILES_CHECK];
        if ([[self.manager getSelectedFiles] containsObject:data])
            [self.manager removeFile:data];
        else
            [self.manager addFile:data];
    }];

    const NSUInteger index = [[self.manager getSelectedFiles] indexOfObject:data];
    const bool found = (index != NSNotFound);
    if (found)
        [fileView setPositionNumber:index + 1];

    [fileView setChecked:found];
}

- (id) initWithManager: (PEXFilePickManager * const) manager
{
    self = [super init];
    self.manager = manager;
    return self;
}

- (void) postLoad
{
    [self.manager addListener:self];
}

- (void) onDismiss
{
    [self.manager deleteListener:self];
    self.manager = nil;
}

- (void) fileAdded: (const PEXFileData * const) asset at: (const NSUInteger) position
{
    [self.controller selectionChanged];
}

- (void) fileRemoved: (const PEXFileData * const) asset at:(const NSUInteger) position
{
    [self.controller selectionChanged];
}

- (void)notifyOverlapError
{
    // do Nothing
}

- (void) clearSelection
{
    [self.controller selectionChanged];
}

- (void) fillIn: (NSArray * const) files
{
    [self.controller selectionChanged];
}

@end
