//
//  AnimationOnClickStub.h
//  Phonex
//
//  Created by Matej Oravec on 20/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

// ---------------------------------------------------------------------
// ------ click animation: not doable by categories = copying everywhere
// ---------------------------------------------------------------------

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enabled)
    {
        [self animateHighlight];
        [super touchesBegan:touches withEvent:event];
    }
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enabled)
    {
        [self animateNormal];
        [super touchesEnded:touches withEvent:event];
    }
}

-(void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.enabled)
    {
        [self animateNormal];
        [super touchesCancelled:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{

    // DO NOTHING because of glitch no moving fingers
}

// TODO replace selector
-(void) animateStateChange: (SEL) action
{
    // NOTE: the animation causes some responsitivity glitches
    // like at the FilesController
    //[UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
        [self performSelector:action];
    //}];
}

-(void) animateHighlight
{
    [self animateStateChange:@selector(setStateHighlight)];
}

-(void) animateNormal
{
    [self animateStateChange:@selector(setStateNormal)];
}

-(void) animateDisabled
{
    [self animateStateChange:@selector(setStateDisabled)];
}
