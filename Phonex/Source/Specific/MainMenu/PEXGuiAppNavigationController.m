//
//  PEXGuiAppNavigationController.m
//  Phonex
//
//  Created by Matej Oravec on 05/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiAppNavigationController.h"
#import "PEXGuiAppNavigationController_Protected.h"


#import "PEXGuiNotificationCounterView.h"

@interface PEXGuiAppNavigationController ()

@property (nonatomic) PEXGuiNotificationCounterView * counter;

@end

@implementation PEXGuiAppNavigationController

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.counter = [[PEXGuiNotificationCounterView alloc] init];
    [self.B_backClickWrapper addSubview:self.counter];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [[PEXGNFC instance] unregisterForAll:self.counter];

    [super viewWillDisappear:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [[PEXGNFC instance] registerToAllAndSet:self.counter];
    [super viewDidAppear:animated];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU move:self.counter rightOf:self.B_back withMargin:PEXVal(@"dim_size_nano")];
    [PEXGVU centerVertically:self.counter];
}

@end
