//
//  PEXGuiExternUrlManager.m
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiExternUrlManager.h"

#import "PEXContactSelectManager.h"
#import "PEXGuiContactsSelectController.h"
#import "PEXGuiSelectContactsNavigationController.h"
#import "PEXGuiLoginController.h"
#import "PEXFileData.h"
#import "PEXFileData.h"
#import "PEXSelectedFileContainer.h"

@interface PEXGuiExternUrlManager ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) PEXGrandSelectionManager * grandManager;

@end

// TODO not dealing with PEXNFC going to foreground ... see PinLockManager
// may cause readng message even if not
@implementation PEXGuiExternUrlManager

+ (PEXGuiExternUrlManager *) instance
{
    static PEXGuiExternUrlManager * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiExternUrlManager alloc] init];
    });

    return instance;
}

- (bool)sendExternalData: (PEXFileData * const) fileData
{
    bool result = false;

    UIViewController * const landing = [PEXGuiLoginController instance].landingController;
    // logged in?
    if (landing)
    {
        [self.lock lock];

        // must be rememberred for other concurrent request to process external URL
        if (self.grandManager)
            // not safe .. see disintegrated
            [self.grandManager disintegrate];

        self.grandManager = [[PEXGrandSelectionManager alloc] init];
        [self.grandManager addListener:self];

        self.grandManager.selectedFileContainers =
                @[[PEXSelectedFileContainer containerFromFileData:fileData]];

        // show contacts:
        PEXContactSelectManager * const manager = [[PEXContactSelectManager alloc] init];

        PEXGuiContactsSelectController * const contactListController =
            [[PEXGuiContactsSelectController alloc] initWithManager:manager];

        PEXGuiSelectContactsNavigationController * const contactSelectNavgation =
            [[PEXGuiSelectContactsNavigationController alloc] initWithViewController:contactListController title:PEXStrU(@"L_select_contacts") manager:manager
                                                                grandManager:self.grandManager];

        [contactSelectNavgation prepareOnScreen:landing];
        [PEXGVU executeWithoutAnimations:^{
            [contactSelectNavgation show:landing];
        }];

        [self.lock unlock];
        result = true;
    }

    return result;
}

// not safe ... because in open it is called in lock and
// it cannot be that way
- (void) disintegrated
{
    [self.grandManager removeListener:self];
    self.grandManager = nil;
}

@end
