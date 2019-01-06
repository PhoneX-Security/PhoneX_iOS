//
// Created by Matej Oravec on 20/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRestRequester.h"


@interface PEXCaptchaLoader : PEXRestRequester

- (bool) loadCaptchaAsyncForHeight: (const CGFloat) heightInPoints
                        completion: (void (^)(UIImage * const))completion
                      errorHandler: (void (^)(void))errorHandler;

@end