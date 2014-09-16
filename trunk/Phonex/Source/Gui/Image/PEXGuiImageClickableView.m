//
//  PEXGuiImageClickableView.m
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiImageClickableView.h"

@implementation PEXGuiImageClickableView

- (id)init
{
    self = [super init];

    self.userInteractionEnabled = YES;

    return self;
}

-(void) addAction:(id)target action:(SEL)action
{
    UITapGestureRecognizer * answerTap = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    answerTap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:answerTap];
}


// ---------------------------------------------------------------------
// ------ click animation: not doable by categories = copying everywhere
// ---------------------------------------------------------------------

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self animateHighlight];
    [super touchesBegan:touches withEvent:event];
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self animateNormal];
    [super touchesEnded:touches withEvent:event];
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self animateNormal];
    [super touchesCancelled:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{

    // DO NOTHING because of glitch no moving fingers
}

// TODO replace selector
-(void) animateStateChange: (SEL) action
{
    [UIView animateWithDuration:PEXVal(@"B_stateAnimation") animations:^{
        [self performSelector:action];
    }];
}

-(void) animateHighlight
{
    [self animateStateChange:@selector(setStateHighlight)];
}

-(void) animateNormal
{
    [self animateStateChange:@selector(setStateNormal)];
}

@end
