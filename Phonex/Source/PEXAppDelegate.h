//
//  PEXAppDelegate.h
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PEXCredentials;

@interface PEXAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

+ (bool) startAutoLoginOnSuccess: (void (^)(void))onSuccess
        onFailureWithCredentials: (void (^)(const PEXCredentials *))onFailed;

@end
