//
//  PEXGuiPinLockButton.m
//  Phonex
//
//  Created by Matej Oravec on 02/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPinLockButton.h"
#import "PEXGuiSimpleButton_Protected.h"

@implementation PEXGuiPinLockButton

- (id)initWithText:(NSString * const) text
{
    return [self initWithText:text fontSize:PEXVal(@"dim_size_large")];
}

-(void) animateStateChange: (SEL) action
{
    // pin lock button feedback must be as fast as possible
    
    //[UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
        [self performSelector:action];
    //}];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (UIColor *)bgColorNormalStatic {return PEXCol(@"white_normal");}
- (UIColor *)bgColorHighlightStatic {return PEXCol(@"light_orange_normal");}
- (UIColor *)bgColorDisabledStatic {return PEXCol(@"white_normal");} // not blinking

@end
