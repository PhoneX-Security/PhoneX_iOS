//
//  PEXGuiTabController.h
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiControllerDecorator.h"

@interface PEXGuiTabController : PEXGuiControllerDecorator

@property (nonatomic, copy) void (^tabSelected)(const NSUInteger, const NSUInteger);
@property (nonatomic, copy) void (^tabDidReveal)(const NSUInteger);

- (id) initWithTabViews: (const NSArray * const) tabContainers;


@end
