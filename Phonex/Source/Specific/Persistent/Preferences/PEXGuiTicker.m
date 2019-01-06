//
// Created by Matej Oravec on 29/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiTicker.h"
#import "PEXGuiPhonexCheckBox.h"
#import "PEXGuiClassicLabel.h"

@interface PEXGuiTicker()
{

}

@property (nonatomic) BOOL displayTitle;
@property (nonatomic) PEXGuiBaseLabel * L_title;
@property (nonatomic) UILabel * L_description;
@property (nonatomic) PEXGuiPhonexCheckBox * CB_checker;
@property (nonatomic) PEXGuiClickableView * B_clicker;

@end

@implementation PEXGuiTicker {

}

- (id) init
{
    self = [super init];
    self.displayTitle = NO;

    self.L_description = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")];
    [self addSubview:self.L_description];

    self.CB_checker = [[PEXGuiPhonexCheckBox alloc] init];
    [self addSubview:self.CB_checker];

    self.B_clicker = [[PEXGuiClickableView alloc] init];
    [self addSubview:self.B_clicker];

    return self;
}

- (instancetype)initWithDisplayTitle:(BOOL)displayTitle {
    self = [self init];
    if (self) {
        self.displayTitle = displayTitle;

        self.L_title = [[PEXGuiClassicLabel alloc]
                initWithFontSize:PEXVal(@"dim_size_small_medium")
                       fontColor:PEXCol(@"light_gray_low")];
        [self addSubview:self.L_title];
    }

    return self;
}

+ (instancetype)tickerWithDisplayTitle:(BOOL)displayTitle {
    return [[self alloc] initWithDisplayTitle:displayTitle];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    if (self.displayTitle){
        [PEXGVU moveAboveCenter:self.L_title];
        [PEXGVU moveBelowCenter:self.L_description];
        [PEXGVU moveToLeft: self.L_title withMargin:PEXVal(@"dim_size_large")];

        // TODO: extend so it works with sizeToFit call.
        NSNumber * maxWidth = @(self.frame.size.width - 3*PEXVal(@"dim_size_large"));
        NSNumber * maxHeight = nil;// @(self.frame.size.height - 3*PEXVal(@"dim_size_large"));
        [self.L_title sizeToFitMaxWidth:maxWidth maxHeight:maxHeight];

    } else {
        [PEXGVU centerVertically:self.L_description];
    }
    [PEXGVU moveToLeft: self.L_description withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU setSize:self.CB_checker x:PEXVal(@"dim_size_large") y:PEXVal(@"dim_size_large")];
    [PEXGVU centerVertically:self.CB_checker];
    [PEXGVU moveToRight: self.CB_checker withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleFull: self.B_clicker];
    [self bringSubviewToFront:self.B_clicker];
}

- (void)setTitle:(NSString *const)label {
    if (!self.displayTitle){
        return;
    }

    self.L_title.text = label;
//    self.L_title.lineBreakMode = NSLineBreakByWordWrapping;
//    self.L_title.numberOfLines = 1;
}

- (void) setLabel: (NSString * const) label
{
    self.L_description.text = label;
}

- (void) setChecked: (const bool) checked
{
    [self.CB_checker setChecked:checked];
}

- (bool) isChecked
{
    return self.CB_checker.isChecked;
}

@end