//
//  PEXGuiButton.m
//  Phonex
//
//  Created by Matej Oravec on 31/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButton.h"
#import "PEXGuiButton_Protected.h"

#import "PEXResValues.h"
#import "PEXResColors.h"

@interface PEXGuiButton ()

@end

@implementation PEXGuiButton

- (id)init
{
    self = [super init];

    [self setStyle];
    
    return self;
}

// TODO save values of sizes and color and use them instead of always lookinp up using the key
+ (CGFloat) fontSize
{
    return PEXVal(@"contentMarginMedium");
}

+ (CGFloat) padding
{
    return PEXVal(@"contentMarginMedium");
}

+ (CGFloat) height
{
    return [self fontSize] + (2.0f * [self padding]);
}

- (void) setStyle
{
    self.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self setBackgroundColor:[self bgColorNormal]];
    [self setTitleColor:[self textColorNormal] forState:UIControlStateNormal];
    self.titleLabel.font = [UIFont boldSystemFontOfSize: [PEXGuiButton fontSize]];
    // width is set by a controller
    self.frame = CGRectMake(0.0f, 0.0f, PEXDefaultVal, [PEXGuiButton fontSize] + (2.0f * [PEXGuiButton padding]));
}

// MAINTENANCE

-(void) setStateHighlight
{
    [self setState:[self bgColorHighlight]
              text:[self textColorHighlight]];
}

-(void) setStateNormal
{
    [self setState:[self bgColorNormal]
              text:[self textColorNormal]];
}

-(void) setState: (UIColor * const) bgColor
            text: (UIColor * const) txtColor
{
    [self setBackgroundColor:bgColor];
    [self setTitleColor:txtColor forState:UIControlStateNormal];
}

- (UIColor *) textColorNormal {return nil;}
- (UIColor *) textColorHighlight {return nil;}
- (UIColor *) bgColorNormal {return nil;}
- (UIColor *) bgColorHighlight {return nil;}

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
