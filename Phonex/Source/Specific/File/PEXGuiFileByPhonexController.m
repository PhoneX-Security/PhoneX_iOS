//
//  PEXGuiFileByPhonexController.m
//  Phonex
//
//  Created by Matej Oravec on 11/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileByPhonexController.h"
#import "PEXGuiFileController_Protected.h"

@implementation PEXGuiFileByPhonexController

- (void) loadContent
{
    [self loadTransferredFiled];
}

- (void) loadTransferredFiled
{
    NSFileManager * const fileManager = [NSFileManager defaultManager];
    NSString * const transferPath = [PEXGuiFileUtils getFileTransferPath];

    NSArray * const directoryContent =
        [fileManager contentsOfDirectoryAtPath:transferPath error:nil];

    // check file type
    // http://stackoverflow.com/questions/17145844/iphone-how-to-check-if-the-file-is-a-directory-audio-video-or-image
    [self dataLoadStarted];
    for (NSString * const filename in directoryContent) {
        {
            if (_cancel)
            {
                _finished = true;
                break;
            }

            NSString * const fullPath = [transferPath stringByAppendingPathComponent:filename];

            PEXGuiItemHelper * const helper = [[PEXGuiItemHelper alloc] init];
            helper.date = [[fileManager attributesOfItemAtPath:fullPath error:nil] fileModificationDate];
            helper.url = [NSURL fileURLWithPath:fullPath];
            [self addFileHelper:helper];
        }
    }
    [self dataLoadFinished];
}

- (void)initGuiComponents {
    [super initGuiComponents];
    self.screenName = @"FilesPhonex";
}

@end