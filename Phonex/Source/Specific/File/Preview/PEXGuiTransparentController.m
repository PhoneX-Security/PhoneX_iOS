//
//  PEXGuiFileOptionsController.m
//  Phonex
//
//  Created by Matej Oravec on 13/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiTransparentController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiBackgroundView.h"

@implementation PEXGuiTransparentController

// NEEDS TO BE MODAL, BECAUSE OF OPENING IN ANOTHER APPLICATION ISSUE
/*
- (void) show:(UIViewController * const) parent
{

    [PEXGVU set: self.view x:[[UIScreen mainScreen] bounds].size.width];
    // INSERT ADDS ALSO THE VIEW'S CONTROLLER AS A CHILD
    //[self addSelfAsChildIfNotAdded:parent];
    [parent.view.window insertSubview:self.view aboveSubview:parent.view];

    [PEXGVU set: self.view x:0.0f];
}
*/

- (UIView *) getMainView
{
    return [[PEXGuiBackgroundView alloc] initWithColor:PEXCol(@"invisible")];
}

- (UIView *) getBackgroundView
{
    return [[PEXGuiBackgroundView alloc] initWithColor:PEXCol(@"invisible")];
}

@end
