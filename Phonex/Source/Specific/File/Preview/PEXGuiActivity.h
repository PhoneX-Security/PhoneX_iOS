//
//  PEXGuiActivity.h
//  Phonex
//
//  Created by Matej Oravec on 10/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PEXGuiActivity : UIActivity

@property (nonatomic) UIViewController * superController;
@property (nonatomic, weak) id activityController;


- (bool) canPerformWithItem: (const id) item;
- (void) present;

@end
