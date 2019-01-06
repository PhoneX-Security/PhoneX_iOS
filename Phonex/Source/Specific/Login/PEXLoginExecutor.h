//
//  PEXLoginExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 20/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiExecutor.h"

#import "PEXLoginTaskResultDescription.h"
#import "PEXTaskListener.h"
#import "PEXGuiLoginController.h"

#import "PEXGuiLoginExecutorListener.h"

@class PEXGuiController;
@class PEXCredentials;

@interface PEXLoginExecutor : PEXGuiExecutor<PEXTaskListener>

-(id) initWithCredentials: (const PEXCredentials * const) credentials
              parentController: (PEXGuiController * const) parentController;

+ (void) loginAftermath: (NSString * const) username;
+ (void)showLoggedGui: (const bool) animated;

@end
