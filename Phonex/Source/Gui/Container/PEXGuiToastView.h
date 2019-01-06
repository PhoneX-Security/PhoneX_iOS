//
// Created by Dusan Klinec on 09.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PEXGuiToastView : UIView
@property (strong, nonatomic) NSString *text;

+ (void)showToastInParentView: (UIView *)parentView
                     withText:(NSString *)text
                 withDuration:(float)duration
               withCompletion:(dispatch_block_t) completion;

@end