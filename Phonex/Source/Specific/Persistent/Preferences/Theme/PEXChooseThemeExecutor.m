//
//  PEXCooseThemeExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 20/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXChooseThemeExecutor.h"

#import "PEXGuiChooseThemeController.h"
#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiFactory.h"
#import "PEXGuiTextController.h"

@interface PEXChooseThemeExecutor ()

@property (nonatomic) PEXGuiController * parent;

@property (nonatomic) PEXGuiChooseThemeController *controller;

@end

@implementation PEXChooseThemeExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;

    return self;
}

- (void)show
{
    self.controller = [[PEXGuiChooseThemeController alloc] init];
    self.topController = [self.controller showInWindowWithTitle:self.parent
                                                   title:PEXStrU(@"L_graphic_theme")
                                      withBinaryListener:self];

    [super show];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [self.parent viewDidReveal];
    [super dismissWithCompletion:completion];
}

- (void)secondaryButtonClicked
{
    [self dismissWithCompletion:nil];
}

- (void)primaryButtonClicked
{
    const NSInteger selectedTheme = [self.controller getSelectedStatus];

    //[PEXAppPreferences setGuiTheme:selectedTheme];
    [[PEXAppPreferences instance] setIntPrefForKey:PEX_PREF_GUI_THEME_KEY value:selectedTheme];

    void (^ completion)(void) = nil;
    if (selectedTheme != [PEXTheme getCurrentTheme])
    {
        completion = ^{
            [PEXGuiFactory showRestartAppChallenge:self.parent];
        };
    }

    [self dismissWithCompletion:completion];
}

@end
