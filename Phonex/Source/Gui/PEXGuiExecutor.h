//
//  PEXGuiExecutor.h
//  Phonex
//
//  Created by Matej Oravec on 16/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXGuiExecutor : NSObject

// move to protected
// top controller created from internal process of execution
@property (nonatomic) PEXGuiController * topController;

// parent controller given from caller to show content on
@property (nonatomic) UIViewController * parentController;

- (void) show;
- (void) dismissWithCompletion: (void (^)(void))completion;

@end
