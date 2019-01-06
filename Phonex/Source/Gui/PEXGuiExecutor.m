//
//  PEXGuiExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 16/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"
#import "PEXReport.h"

@interface PEXGuiExecutor ()

@end

@implementation PEXGuiExecutor

- (void)show
{
    [PEXUnmanagedObjectHolder addActiveObject:self forKey:self.topController];
}

- (void) dismissWithCompletion: (void (^)(void))completion
{
    [self.topController viewDidReveal];
    [self.topController dismissViewControllerAnimated:true completion:completion];
}

@end
