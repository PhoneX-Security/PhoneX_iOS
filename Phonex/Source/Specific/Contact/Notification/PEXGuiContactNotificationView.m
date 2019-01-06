//
// Created by Matej Oravec on 06/08/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiContactNotificationView.h"
#import "PEXDbContactNotification.h"
#import "PEXGuiImageView.h"
#import "PEXGuiClassicLabel.h"

@interface PEXGuiContactNotificationView()

@property (nonatomic) UILabel * L_username;
@property (nonatomic) PEXGuiImageView * I_image;

@property (nonatomic) PEXGuiClassicLabel * L_date;
@property (nonatomic) PEXGuiClassicLabel * L_time;

@end

@implementation PEXGuiContactNotificationView {

}

- (void) initGui
{
    self.L_username = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")
                                                           fontColor:PEXCol(@"black_normal")];
    [self addSubview:self.L_username];

    self.I_image = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"contact_request")];
    [self addSubview:self.I_image];

    self.L_date = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_date];

    self.L_time = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_time];
}

- (void) applyNotification:  (const PEXDbContactNotification * const) notification;
{
    self.L_username.text = notification.username;

    self.L_date.text = [PEXDateUtils dateToDateString:notification.date];
    self.L_time.text = [PEXDateUtils dateToTimeString:notification.date];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.I_image];

    const CGFloat margin = [self getMargin];

    [PEXGVU moveToLeft:self.I_image withMargin:margin];


    [PEXGVU scaleHorizontally:self.L_username from:self.I_image
                   leftMargin:margin rightMargin:PEXVal(@"dim_size_large")];

    [PEXGVU centerVertically:self.L_username];

    [PEXGVU moveToRight:self.L_date withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveAboveCenter: self.L_date];
    [PEXGVU setWidth:self.L_username until:self.L_date withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU moveToRight:self.L_time withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveBelowCenter: self.L_time];
}

- (CGFloat) getMargin
{
    return ([self staticHeight] - self.I_image.frame.size.width) / 2;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


@end