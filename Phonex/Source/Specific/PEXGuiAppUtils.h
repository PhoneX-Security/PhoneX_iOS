//
//  PEXGuiAppUtils.h
//  Phonex
//
//  Created by Matej Oravec on 05/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGuiAppNavigationController.h"

#define PEXGAU PEXGuiAppUtils

@interface PEXGuiAppUtils : NSObject

+ (PEXGuiController *) showInNavigation: (PEXGuiController * const) controller
                                     in:(UIViewController * const) parent
                                  title: (NSString * const) title;

+ (PEXGuiController *) showInNavigation:(PEXGuiController * const) controller
                                     in:(UIViewController * const) parent
                                  title:(NSString * const) title
                             completion:(dispatch_block_t) completion;

@end
