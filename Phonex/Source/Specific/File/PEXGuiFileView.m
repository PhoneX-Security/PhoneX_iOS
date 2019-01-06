//
//  PEXGuiFileView.m
//  Phonex
//
//  Created by Matej Oravec on 02/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileView.h"
#import "PEXGuiRowItemView_Protected.h"

#import "PEXGuiImageView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiTick.h"
#import "PEXGuiWindowMainView.h"

#import "PEXGuiFileUtils.h"
#import "PEXGuiClickableView.h"
#import "PEXGuiPoint.h"
#import "PEXGuiThumailView.h"
#import "PEXGuiActivityIndicatorView.h"

@interface PEXGuiFileView ()
{
@private
    bool _checked;
    NSUInteger _position;
}

@property (nonatomic) UILabel *L_size;
@property (nonatomic) PEXGuiClassicLabel * L_date;
@property (nonatomic) PEXGuiClassicLabel * L_time;

@property (nonatomic) PEXGuiClickableView * B_thumbNail;

@property (nonatomic) UIView * V_selectedDim;
@property (nonatomic) UILabel * L_orderNumber;

@property (nonatomic) PEXGuiActivityIndicatorView * indicator;

@end

@implementation PEXGuiFileView

- (PEXGuiClickableView *) getCheckView
{
    return self.B_thumbNail;
}

- (bool) isChecked
{
    return _checked;
}

- (NSUInteger) position
{
    return _position;
}

- (void) check
{
    _checked = !_checked;
    [self.V_selectedDim setHidden: !_checked];
}

- (void) setChecked: (const bool) checked
{
    if (_checked != checked)
        [self check];
}

- (void) setPositionNumber: (const int) position
{
    _position = position;
    self.L_orderNumber.text = [NSString stringWithFormat:@"%d", position];
    [PEXGVU center:self.L_orderNumber];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU moveAboveCenter:self.L_fileName];

    [PEXGVU scaleFull:self.B_thumbNail];

    [PEXGVU scaleFull:self.indicator];

    [PEXGVU moveBelowCenter:self.L_size];
    [PEXGVU scaleHorizontally:self.L_size from:self.V_separator
                   leftMargin:PEXVal(@"dim_size_large") rightMargin:PEXVal(@"dim_size_large")];

    [PEXGVU moveToRight:self.L_date withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveAboveCenter: self.L_date];
    [PEXGVU setWidth:self.L_fileName until:self.L_date withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU moveToRight:self.L_time withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveBelowCenter: self.L_time];
    [PEXGVU setWidth:self.L_size until:self.L_time withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleFull:self.V_selectedDim];
    [PEXGVU center:self.L_orderNumber];

    [self layoutImage];
}

- (void) initGui
{
    [super initGui];

    self.L_size = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                        fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_size];

    self.L_date = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_date];

    self.L_time = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                     fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_time];


    self.indicator = [[PEXGuiActivityIndicatorView alloc] init];
    [self.V_thumbNail addSubview:self.indicator];

    self.B_thumbNail = [[PEXGuiClickableView alloc] init];
    [self.V_thumbNail addSubview:self.B_thumbNail];

    self.V_selectedDim = [[PEXGuiWindowMainView alloc] init];
    [self.B_thumbNail addSubview:self.V_selectedDim];

    self.L_orderNumber = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")
                                                            fontColor:PEXCol(@"orange_low")];
    [self.V_selectedDim addSubview:self.L_orderNumber];

    self.B_thumbNail.exclusiveTouch = true;

    _checked = true;
    [self setChecked:false];
}

- (void) applyAsset: (const PEXFileData * const) data
{
    if (data) {
        [self setIndicating:false];

        [self applyThumb:data.thumbnail filename:data.filename];

        self.L_date.text = [PEXDateUtils dateToDateString:data.date];
        self.L_time.text = [PEXDateUtils dateToTimeString:data.date];

        self.L_size.text = [[PEXGuiFileUtils bytesToRepresentation:data.size] description];
    }
    else
    {
        [self applyThumb:data.thumbnail filename:data.filename];

        self.L_date.text = @"...";
        self.L_time.text = @"...";

        self.L_size.text = @"...";

        [self setIndicating:true];
    }


}

- (void) setIndicating: (const bool) indicate
{
    [self.B_thumbNail setHidden:indicate];
    [self.I_thumbnail setHidden:indicate];
    [self.indicator setHidden:!indicate];

    [self.indicator performSelector:(indicate ? @selector(startAnimating) : @selector(stopAnimating))];
}

- (UIColor *)bgColorDisabledStatic {return PEXCol(@"white_normal");}

@end
