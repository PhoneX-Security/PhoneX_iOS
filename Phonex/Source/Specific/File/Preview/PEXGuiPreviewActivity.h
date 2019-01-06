//
//  PEXGuiPreviewActivity.h
//  Phonex
//
//  Created by Matej Oravec on 09/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import "PEXGuiActivity.h"
#import "PEXGuiPreviewExecutor.h"


@class PEXGuiPreviewActivity;

@interface PEXGuiPreviewActivity : PEXGuiActivity<PEXGuiPreviewDelegate>

@property (nonatomic) id <PEXGuiPreviewDelegate> delegate;

@end
