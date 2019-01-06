//
// Created by Dusan Klinec on 12.09.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef PEX_GAI_TRACKING
#  define PEX_GAI_TRACKING 0
#endif

#if PEX_GAI_TRACKING
#  import "GAITrackedViewController.h"
#endif

#if PEX_GAI_TRACKING
@interface PEXGuiTrackingController : GAITrackedViewController
#else
@interface PEXGuiTrackingController : UIViewController
#endif

// Fake properties in case of no Google analytics is included in the project.
#if PEX_GAI_TRACKING
#else
@property(nonatomic) id tracker;
@property(nonatomic) NSString* screenName;
#endif

@end