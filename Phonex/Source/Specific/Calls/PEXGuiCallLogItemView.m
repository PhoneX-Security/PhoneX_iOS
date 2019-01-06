//
//  PEXGuiCallLogItemView.m
//  Phonex
//
//  Created by Matej Oravec on 20/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCallLogItemView.h"

#import "PEXGuiMenuLine.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiFullArrowDown.h"
#import "PEXGuiFullArrowUp.h"
#import "PEXGuiImageView.h"


@interface PEXGuiCallLogItemView ()

@property (nonatomic) PEXGuiClassicLabel * L_name;
@property (nonatomic) PEXGuiClassicLabel * L_date;
@property (nonatomic) PEXGuiClassicLabel * L_time;

@property (nonatomic) UIView *statusView;

@end

@implementation PEXGuiCallLogItemView

- (id)initWithCallLog:(const PEXGuiCallLog *const)callLog
{
    self = [super init];

    [self initGuiStuff];
    [self applyGuiCallLog:callLog];

    return self;
}

- (void) applyGuiCallLog:(const PEXGuiCallLog *const)callLog
{
    [self applyContact:callLog.contact];
    [self applyCallLog:callLog.callLog];
}

- (void) initGuiStuff
{
    self.L_name = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")
                                                     fontColor:PEXCol(@"black_normal")];
    self.L_name.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.L_name];

    self.L_date = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_date];

    self.L_time = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_time];
}

- (void) applyContact: (const PEXDbContact * const) contact
{
    // TODO check equality when more added
    self.L_name.text = contact.displayName;
}

+ (bool) contact: (const PEXDbContact * const) c1
     needsUpdate: (const PEXDbContact * const) c2
{
    return ![c1.displayName isEqualToString: c2.displayName];
}

- (void) applyCallLog:(const PEXDbCallLog *const)callLog
{
    // not compared because of creation of other strings // TODO store date?
    self.L_date.text = [PEXDateUtils dateToDateString:callLog.callStart];
    self.L_time.text = [PEXDateUtils dateToTimeString:callLog.callStart];

    UIView * statusView;

    const int status = [callLog.type integerValue];
    if (status == PEX_DBCLOG_TYPE_OUTGOING)
    {
        statusView = [[PEXGuiFullArrowUp alloc] initWithColor:PEXCol(@"green_normal")];
    }
    else if (status == PEX_DBCLOG_TYPE_INCOMING)
    {
        statusView = [[PEXGuiFullArrowDown alloc] initWithColor:PEXCol(@"red_normal")];
    }
    else
    {
        statusView = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"call_missed")];
    }

    [self.statusView removeFromSuperview];
    self.statusView = statusView;
    [self addSubview:statusView];
}

+ (bool) callLog: (const PEXDbCallLog * const) c1
     needsUpdate: (const PEXDbCallLog * const) c2
{
    const bool result = (![c1.type isEqualToNumber:c2.type]) ||
                        (c1.seenByUser != c2.seenByUser);

    return result;
}

- (void) highlighted
{
    [self setNotificationColor:PEXCol(@"orange_low")];
}

- (void) normal
{
    [self setNotificationColor:PEXCol(@"light_gray_low")];
}

- (void) setNotificationColor: (UIColor * const) color
{
    self.L_date.textColor = color;
    self.L_time.textColor = color;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.statusView];

    const CGFloat margin = ([self staticHeight] - self.statusView.frame.size.width) / 2;
    [PEXGVU moveToLeft:self.statusView
            withMargin:margin];


    [PEXGVU moveToLeft:self.L_name withMargin:[self staticHeight]];
    [PEXGVU centerVertically:self.L_name];

    [PEXGVU moveToRight:self.L_date withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveAboveCenter: self.L_date];
    [PEXGVU setWidth:self.L_name until:self.L_date withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU moveToRight:self.L_time withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveBelowCenter: self.L_time];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
