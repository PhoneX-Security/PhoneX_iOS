//
//  PEXGuiMainTabControllerViewController.m
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiMainTabController.h"
#import "PEXGuiTabController_Protected.h"

#import "PEXGuiMainNavigationController.h"

@interface PEXGuiMainTabController ()

@end

@implementation PEXGuiMainTabController

- (PEXGuiController *)showInLabel:(UIViewController *const)parent title:(NSString *const)title
                         animated: (const bool) animated
{
    PEXGuiMainNavigationController * a = [[PEXGuiMainNavigationController alloc]
                                 initWithViewController:self
                                 title:title];

    a.tabController = self;
    [a prepareOnScreen:parent];
    [a show:parent animated:animated];
    return a;
}

@end
