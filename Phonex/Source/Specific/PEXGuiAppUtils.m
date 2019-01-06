//
//  PEXGuiAppUtils.m
//  Phonex
//
//  Created by Matej Oravec on 05/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiAppUtils.h"

@implementation PEXGuiAppUtils

+ (PEXGuiController *) showInNavigation: (PEXGuiController * const) controller
                                     in:(UIViewController * const) parent
                                  title: (NSString * const) title
{
    PEXGuiNavigationController * a = [[PEXGuiAppNavigationController alloc]
                                      initWithViewController:controller
                                      title:title];

    [a prepareOnScreen:parent];
    [a show:parent];
    return a;
}

+ (PEXGuiController *) showInNavigation:(PEXGuiController * const) controller
                                     in:(UIViewController * const) parent
                                  title:(NSString * const) title
                             completion:(dispatch_block_t) completion
{
    PEXGuiNavigationController * a = [[PEXGuiAppNavigationController alloc]
                                      initWithViewController:controller
                                      title:title];

    [a prepareOnScreen:parent];
    [a show:parent animated:YES completion:completion];
    return a;
}

@end
