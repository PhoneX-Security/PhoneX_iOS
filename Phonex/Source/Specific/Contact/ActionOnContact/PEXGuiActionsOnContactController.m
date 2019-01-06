 //
//  PEXGuiUserDialog.m
//  Phonex
//
//  Created by Matej Oravec on 06/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiActionsOnContactController.h"
#import "PEXGuiController_Protected.h"
#import "PEXGuiControllerDecorator.h"

#import "PEXGuiLinearScalingView.h"
#import "PEXGuiActionOnContactView.h"

#import "PEXGuiActionOnContactBackgroundView.h"

#import "PEXGuiImageView.h"

@interface PEXGuiActionsOnContactController ()

@property (nonatomic) PEXGuiLinearContainerView * B_rowOne;
@property (nonatomic) PEXGuiLinearContainerView * B_rowTwo;
@property (nonatomic) PEXGuiActionOnContactView * V_call;
@property (nonatomic) PEXGuiActionOnContactView * V_message;
@property (nonatomic) PEXGuiActionOnContactView * V_file;
@property (nonatomic) PEXGuiActionOnContactView * V_settings;

@property (nonatomic) id<PEXGuiActionOnContactListener> listener;

@end

@implementation PEXGuiActionsOnContactController

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ContactActions";

    self.B_rowOne = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
    [self.mainView addSubview:self.B_rowOne];

    self.V_message = [[PEXGuiActionOnContactView alloc] initWithImage:
                      [[PEXGuiImageView alloc]
                       initWithImage:PEXImg(@"chat")]
                                                            labelText:PEXStrU(@"B_chat")];
    [self.B_rowOne addView:self.V_message];

    self.V_call = [[PEXGuiActionOnContactView alloc] initWithImage:[[PEXGuiImageView alloc]
                                                                    initWithImage:PEXImg(@"phone")]
                                                         labelText:PEXStrU(@"B_call")];
    [self.B_rowOne addView:self.V_call];

    // SECOND ROW

    self.B_rowTwo = [[PEXGuiLinearScalingView alloc] initWithGapSize:PEXVal(@"line_width_small")];
    [self.mainView addSubview:self.B_rowTwo];

    self.V_file = [[PEXGuiActionOnContactView alloc] initWithImage:[[PEXGuiImageView alloc]
                    initWithImage:PEXImg(@"file")]
                                                         labelText:PEXStrU(@"B_file")];
    [self.B_rowTwo addView:self.V_file];

    self.V_settings = [[PEXGuiActionOnContactView alloc]
                       initWithImage:[[PEXGuiImageView alloc]
                                      initWithImage:PEXImg(@"settings")]
                        labelText:PEXStrU(@"B_details")];
    [self.B_rowTwo addView:self.V_settings];

}

- (UIView *) getMainView
{
    return [[PEXGuiActionOnContactBackgroundView alloc] init];
}

- (UIView *)getBackgroundView
{
    return [[PEXGuiActionOnContactBackgroundView alloc] init];
}

- (void) initContent
{
    [super initContent];

}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.B_rowOne];
    [PEXGVU setHeight:self.B_rowOne to:PEXVal(@"B_imageButton_height")];
    [PEXGVU moveToTop:self.B_rowOne];
    [PEXGVU scaleHorizontally:self.B_rowTwo];
    [PEXGVU setHeight:self.B_rowTwo to:PEXVal(@"B_imageButton_height")];
    [PEXGVU moveToBottom:self.B_rowTwo];
}

- (void) initBehavior
{
    [super initBehavior];

    #define PEX_CALLBACK(name) [self.V_ ## name addAction:self action:@selector(name ## Clicked)]
    PEX_CALLBACK(call);
    PEX_CALLBACK(message);
    PEX_CALLBACK(file);
    PEX_CALLBACK(settings);
}

- (void) setSizeInView: (PEXGuiControllerDecorator * const) parent
{
    //[PEXGVU setWidth:self.mainView to:[parent subviewMaxWidth]];
    [PEXGVU setSize:self.mainView x:[parent subviewMaxWidth] y:(2.0f * PEXVal(@"B_imageButton_height")) + PEXVal(@"line_width_small")];
}

#define PEX_GENERATE_CALLBACK(name) - (void) name ## Clicked { [self.listener name ## Clicked]; }
PEX_GENERATE_CALLBACK(call)
PEX_GENERATE_CALLBACK(message)
PEX_GENERATE_CALLBACK(file)
PEX_GENERATE_CALLBACK(settings)

- (void) setListener: (id<PEXGuiActionOnContactListener>) listener
{
    _listener = listener;
}

@end
