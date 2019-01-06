//
//  PEXChooseLanguageExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 14/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXChooseLanguageExecutor.h"

#import "PEXGuiChooseLanguageController.h"
#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiFactory.h"

#import "PEXGuiTextController.h"

@interface PEXChooseLanguageExecutor ()

@property (nonatomic) PEXGuiController * parent;

@property (nonatomic) PEXGuiChooseLanguageController *chooseLanguageController;

@end

@implementation PEXChooseLanguageExecutor

- (id) initWithParentController: (PEXGuiController * const)parent
{
    self = [super init];

    self.parent = parent;

    return self;
}

- (void)show
{
    self.chooseLanguageController = [[PEXGuiChooseLanguageController alloc] init];
    self.topController = [self.chooseLanguageController showInWindowWithTitle:self.parent
                                               title:PEXStrU(@"L_language")
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
    NSString * const selectedLanguage =
        [self.chooseLanguageController getSelectedLanguage];

    [[PEXAppPreferences instance]
            setStringPrefForKey:PEX_PREF_APPLICATION_LANGUAGE_KEY value:selectedLanguage];

    void (^ completion)(void) = nil;
    if (![selectedLanguage isEqualToString:
          [_PEXStr getCurrentAppLanguage]])
    {
        completion = ^{
            [PEXGuiFactory showRestartAppChallenge:self.parent];
        };
    }

    [self dismissWithCompletion:completion];
}

@end
