//
// Created by Matej Oravec on 17/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileBySelection.h"
#import "PEXGuiFileController_Protected.h"
#import "PEXGuiFileNavigationController.h"


@interface PEXGuiFileBySelection ()

@property (nonatomic) PEXGuiFileNavigationController * navigation;
@property (nonatomic) NSArray * preselectedFiles;

@end

@implementation PEXGuiFileBySelection {

}

- (id) initWithVisitor: (PEXGuiFileControllerVisitor * const) visitor
      preselectedFiles: (NSArray * const) preselectedFiles
{
    self = [super initWithVisitor:visitor];

    self.preselectedFiles = preselectedFiles;

    return self;
}

- (void) loadContent
{
    [self loadPreselectedFiles];
}

- (void) loadPreselectedFiles
{
    [self dataLoadStarted];
    for (PEXFileData * const fileData in self.preselectedFiles)
    {
        PEXGuiItemHelper * const helper = [[PEXGuiItemHelper alloc] init];
        helper.url = fileData.url;
        helper.date = fileData.date;
        [self addFileHelper:helper];
    }
    [self dataLoadFinished];
}

- (void)initGuiComponents {
    [super initGuiComponents];
    self.screenName = @"FilesSelection";
}

@end