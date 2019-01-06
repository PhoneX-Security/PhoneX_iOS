//
// Created by Matej Oravec on 17/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiLabelController.h"
#import "PEXGuiLabelController_Protected.h"

#import "PEXGuiNavigationLabel.h"
#import "PEXGuiControllerDecorator_Protected.h"
#import "PEXGuiImageClickableView.h"
#import "PEXGuiPoint.h"
#import "PEXGuiBackgroundNavigationView.h"
#import "PEXGuiNavigationLine.h"
#import "PEXGuiClassicLabel.h"


@implementation PEXGuiLabelController

- (id) initWithViewController: (PEXGuiController * const) controller
                        title: (NSString * const) title
{
    self = [super initWithViewController:controller];

    self.title = title;

    return self;
}

- (UIView *) getMainView
{
    return [[PEXGuiBackgroundNavigationView alloc] init];
}

- (UIView *)getBackgroundView
{
    return [[PEXGuiBackgroundNavigationView alloc] init];
}

- (void) initGuiComponents
{
    [super initGuiComponents];

    self.V_background = [[PEXGuiBackgroundNavigationView alloc] init];;
    [self.mainView addSubview:self.V_background];

    self.L_title = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium") fontColor:PEXCol(@"light_gray_low")];
    [self.V_background addSubview:self.L_title];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.V_background];
    // dependent on the title label
    [PEXGVU setHeight:self.V_background
                       to:(3.0f * PEXVal(@"dim_size_medium"))];
    [PEXGVU moveToTop:self.V_background];

    [self positionSubcontrollersView:((UIViewController*)self.childViewControllers[0]).view];
}

- (void) positionSubcontrollersView: (UIView * const) subview
{
    [PEXGVU move: subview below:self.V_background];
}

- (void) initContent
{
    [super initContent];

    self.L_title.text = self.title;
}

- (void) initBehavior
{
    [super initBehavior];

    // Needs to be set because then the subviews do not respond ...
    // probably set on NO by default
    self.L_title.userInteractionEnabled = YES;
}

- (void) setLabelText: (NSString * const) text
{
    self.title = text;
    self.L_title.text = text;
    [self fitLabel];
}

- (void) initState
{
    [super initState];

    [self fitLabel];
}

- (void) setStaticSize
{
    [self staticWidth: 0.0f];
    [self staticHeight: [PEXGuiNavigationLabel height]];
}

- (void) fitLabel
{
    [PEXGVU center:self.L_title];

    const CGFloat leftLabelEnd = [self leftLabelEnd];
    if (self.L_title.frame.origin.x < leftLabelEnd)
    {
        [PEXGVU set:self.L_title x:leftLabelEnd];
    }

    const CGFloat rightLabelEnd = [self rightLabelEnd];
    CGFloat diff = self.L_title.frame.origin.x + self.L_title.frame.size.width - rightLabelEnd;
    if (diff > 0)
    {
        const CGFloat a = (self.L_title.frame.origin.x - [self leftLabelEnd]);
        if (diff > a)
        {
            diff = a;
        }

        [PEXGVU set:self.L_title x:self.L_title.frame.origin.x - diff];
        [PEXGVU setWidth:self.L_title to:rightLabelEnd - self.L_title.frame.origin.x];
    }
}

- (CGFloat) leftLabelEnd
{
    return PEXVal(@"dim_size_large");
}

- (CGFloat) rightLabelEnd
{
    return self.V_background.frame.size.width - PEXVal(@"dim_size_large");
}

@end