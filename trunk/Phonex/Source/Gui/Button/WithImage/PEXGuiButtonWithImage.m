//
//  PEXGuiButtonWithImage.m
//  Phonex
//
//  Created by Matej Oravec on 04/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiButtonWithImage.h"
#import "PEXGuiButtonWithImage_Protected.h"

#import "PEXGuiClassicLabel.h"
#import "PEXGuiImageView.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiButtonWithImage ()

@property (nonatomic) PEXGuiImageView * image;
@property (nonatomic) UILabel * label;

@end

@implementation PEXGuiButtonWithImage

- (id)initWithImage:(UIImage * const) image labelText:(NSString * const) label
{
    self = [self init];

    self.userInteractionEnabled = YES;

    self.image = [[PEXGuiImageView alloc] initWithImage:image];
    [self addSubview:self.image];

    self.label = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"fontSizeMedium")];
    self.label.text = label;
    [self addSubview:self.label];

    [self setStateNormal];

    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU center:self.image];
    [PEXGVU centerHorizontally:self.label];
    [PEXGVU move:self.label below:self.image withMargin:PEXVal(@"distanceNormal")];
}

// MAINTENANCE

-(void) setStateNormal
{
    [self setState:[self bgColorNormal ]
              text:[self textColorNormal]];
    [self.image setStateNormal];
}

-(void) setStateHighlight
{
    [self setState:[self bgColorHighlight]
              text:[self textColorHighlight]];
    [self.image setStateHighlight];
}

-(void) setState: (UIColor * const) bgColor
            text: (UIColor * const) txtColor
{
    [self setBackgroundColor:bgColor];
    [self.label setTextColor:txtColor];

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
