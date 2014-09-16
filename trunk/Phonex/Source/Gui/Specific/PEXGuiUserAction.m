//
//  PEXGuiUserDialog.m
//  Phonex
//
//  Created by Matej Oravec on 06/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiUserAction.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiControllerDecorator.h"

#import "PEXGuiViewRow.h"
#import "PEXGuiButtonUserAction.h"

#import "PEXGuiViewUtils.h"

@interface PEXGuiUserAction ()

@property (nonatomic) PEXGuiViewRow * B_row;
@property (nonatomic) UIView * V_loud;
@property (nonatomic) UIView * V_mute;
@property (nonatomic) UIView * V_more;


@end

@implementation PEXGuiUserAction

- (UIView *) getMainView
{
    return [[PEXGuiViewRow alloc] init];
}


- (void) initGuiComponents
{
    [super initGuiComponents];

    self.B_row = (PEXGuiViewRow *) self.mainView;

    self.V_loud = [[PEXGuiButtonUserAction alloc] initWithImage:[UIImage imageNamed:@"log32.png"]
                                                         labelText:PEXStrU(@"")];
    [self.B_row addView:self.V_loud];
    self.V_mute = [[PEXGuiButtonUserAction alloc] initWithImage:[UIImage imageNamed:@"log32.png"]
                                                         labelText:PEXStrU(@"")];
    [self.B_row addView:self.V_mute];
    self.V_more = [[PEXGuiButtonUserAction alloc] initWithImage:[UIImage imageNamed:@"log32.png"]
                                                         labelText:PEXStrU(@"")];
    [self.B_row addView:self.V_more];
}

- (void) initContent
{
    [super initContent];

}

- (void) initLayout
{
    [super initLayout];
}

- (void) initBehavior
{
    [super initBehavior];

}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    [PEXGVU setWidth:self.mainView to:[parent subviewMaxWidth]];
    [PEXGVU setSize:self.mainView x:[parent subviewMaxWidth] y:PEXVal(@"B_imageButton_height")];
}

@end
