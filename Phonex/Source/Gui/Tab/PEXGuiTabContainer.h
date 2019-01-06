//
//  PEXGuiTabContainer.h
//  Phonex
//
//  Created by Matej Oravec on 24/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiController.h"
#import "PEXGuiTabView.h"

@interface PEXGuiTabContainer : NSObject

@property (nonatomic) PEXGuiController * tabController;
@property (nonatomic) PEXGuiTabView * tabView;

@end
