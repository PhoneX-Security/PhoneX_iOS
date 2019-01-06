//
//  PEXGuiLooseController.m
//  Phonex
//
//  Created by Matej Oravec on 16/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiLooseController.h"
#import "PEXGuiController_Protected.h"



@implementation PEXGuiLooseController

- (void) dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissWithCompletion:completion animation:^{
        [PEXGVU set: self.view y:[[UIScreen mainScreen] bounds].size.height];
    }];
}

// TODO Is not prepared for IN VIEW situation yet ... only fullscreen
- (void) show:(UIViewController * const) parent
{
    [PEXGVU set: self.view y:[[UIScreen mainScreen] bounds].size.height];

    [self addSelfAsChildIfNotAdded:([[parent class] isSubclassOfClass:[PEXGuiController class]] ? ((PEXGuiController*) parent).fullscreener : parent)];

    [UIView beginAnimations: nil context: nil];
    [PEXGVU set: self.view y:0.0f];
    [UIView commitAnimations];
}

@end
