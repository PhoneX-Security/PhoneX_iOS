//
//  PEXGuiSasController.m
//  Phonex
//
//  Created by Matej Oravec on 04/01/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSasController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiClassicLabel.h"
#import "PEXGuiSasHelper.h"
#import "PEXGuiMenuLine.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiTextView_Protected.h"
#import "UITextView+PEXPaddings.h"

@interface PEXGuiSasController ()
{
    bool _isOutgoing;
}
@property (nonatomic) NSString * sas;

@property (nonatomic) PEXGuiReadOnlyTextView * TV_callerInfo;
@property (nonatomic) UILabel * L_callerSas;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_calleeInfo;
@property (nonatomic) UILabel * L_calleeSas;
@property (nonatomic) PEXGuiMenuLine * lineView;

@end

@implementation PEXGuiSasController

- (id) initWithSas: (NSString * const) sas outgoing: (const bool) isOutgoing;
{
    self = [super init];

    self.sas = sas;
    _isOutgoing = isOutgoing;

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"SAS";

    /*
    self.L_callerInfo = [[PEXGuiClassicLabel alloc]  initWithFontSize:PEXVal(@"dim_size_medium") fontColor:PEXCol(@"light_gray_low")];
    [self.mainView addSubview:self.L_callerInfo];
    */
    self.TV_callerInfo = [[PEXGuiReadOnlyTextView alloc] init];
    [self.TV_callerInfo setPadding:0.0f];
    self.TV_callerInfo.textColor = PEXCol(@"light_gray_low");
    [self.mainView addSubview:self.TV_callerInfo];

    self.L_callerSas = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_large")];
    [self.mainView addSubview:self.L_callerSas];

    /*
    self.L_calleeInfo = [[PEXGuiClassicLabel alloc]  initWithFontSize:PEXVal(@"dim_size_medium") fontColor:PEXCol(@"light_gray_low")];
    [self.mainView addSubview:self.L_calleeInfo];
    */

    self.TV_calleeInfo = [[PEXGuiReadOnlyTextView alloc] init];
    [self.TV_calleeInfo setPadding:0.0f];
    self.TV_calleeInfo.textColor = PEXCol(@"light_gray_low");
    [self.mainView addSubview:self.TV_calleeInfo];

    self.L_calleeSas = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_large")];
    [self.mainView addSubview:self.L_calleeSas];

    self.lineView = [[PEXGuiMenuLine alloc] init];
    [self.mainView addSubview:self.lineView];
}

- (void) initContent
{
    [super initContent];

    self.TV_callerInfo.text = [NSString stringWithFormat:@"1. %@:",PEXStr(@"L_sas_caller_info")];
    self.L_callerSas.text = [NSString stringWithFormat:@"%@ %@",
                              [PEXGuiSasHelper translate:[self.sas substringWithRange:NSMakeRange(0, 1)]],
                              [PEXGuiSasHelper translate:[self.sas substringWithRange:NSMakeRange(1, 1)]]];

    self.TV_calleeInfo.text = [NSString stringWithFormat:@"2. %@:",PEXStr(@"L_sas_callee_info")];
    self.L_calleeSas.text = [NSString stringWithFormat:@"%@ %@",
                              [PEXGuiSasHelper translate:[self.sas substringWithRange:NSMakeRange(2, 1)]],
                              [PEXGuiSasHelper translate:[self.sas substringWithRange:NSMakeRange(3, 1)]]];
}

- (void) initLayout
{
    [super initLayout];

    // middle line
    [PEXGVU centerVertically:self.lineView];
    [PEXGVU scaleHorizontally:self.lineView];

    // caller
    [PEXGVU move:self.L_callerSas above:self.self.lineView withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU centerHorizontally:self.L_callerSas];

    [PEXGVU scaleHorizontally:self.TV_callerInfo];
    [self.TV_callerInfo sizeToFit];
    [PEXGVU centerHorizontally:self.TV_callerInfo];
    [PEXGVU move:self.TV_callerInfo above:self.L_callerSas withMargin:PEXVal(@"dim_size_large")];

    // callee
    [PEXGVU scaleHorizontally:self.TV_calleeInfo];
    [self.TV_calleeInfo sizeToFit];
    [PEXGVU centerHorizontally:self.TV_calleeInfo];
    [PEXGVU move:self.TV_calleeInfo below:self.lineView withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU move:self.L_calleeSas below:self.TV_calleeInfo withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU centerHorizontally:self.L_calleeSas];
}

- (void)setSizeInView:(PEXGuiControllerDecorator *const)parent
{
    [PEXGVU setSize:
     self.mainView
                  x:
     parent.subviewMaxWidth
                  y:
     (10 * PEXVal(@"dim_size_large")) +  // 4 x padding, 2 x font size, 4x 2-line cushioon
     1.0f +                             // 1 x line
     (2 * PEXVal(@"dim_size_medium"))   // 2 x font size
     ];
}

@end
