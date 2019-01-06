//
// Created by Matej Oravec on 19/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiSimpleFileView.h"
#import "PEXGuiThumailView.h"
#import "PEXGuiPoint.h"
#import "PEXGuiClassicLabel.h"

@interface PEXGuiSimpleFileView ()

@end


@implementation PEXGuiSimpleFileView {

}

- (void) layoutImage
{
    [PEXGVU scaleFull:self.I_thumbnail];
    [self.I_thumbnail layoutSubviews];
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    const CGFloat height = self.frame.size.height;

    [PEXGVU setSize:self.V_thumbNail x:height y:height];

    [PEXGVU moveToLeft:self.V_thumbNail];

    [PEXGVU scaleFull:self.I_thumbnail];

    [PEXGVU scaleVertically:self.V_separator withMargin:1.0f];
    [PEXGVU move:self.V_separator rightOf:self.V_thumbNail];

    [PEXGVU centerVertically:self.L_fileName];
    [PEXGVU scaleHorizontally:self.L_fileName from:self.V_separator
                   leftMargin:PEXVal(@"dim_size_large") rightMargin:PEXVal(@"dim_size_large")];
}

- (void) initGui
{
    self.L_fileName = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")];
    [self addSubview:self.L_fileName];

    self.V_thumbNail = [[UIView alloc] init];
    [self addSubview:self.V_thumbNail];

    self.I_thumbnail = [[PEXGuiThumailView alloc] init];
    [self.V_thumbNail addSubview:self.I_thumbnail];

    self.V_separator = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [self addSubview:self.V_separator];
}

- (void) applyThumb: (UIImage * const) thumb filename: (NSString * const) filename
{
    self.L_fileName.text = filename;
    [self.I_thumbnail setImage:thumb];

    [self layoutImage];
}

- (CGFloat) staticHeight
{
    return [PEXGuiSimpleFileView staticHeight];
}

+ (CGFloat) staticHeight
{
    return [PEXResValues getThumbnailSize];
}

@end