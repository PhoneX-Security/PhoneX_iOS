//
// Created by Matej Oravec on 18/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPackageView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXPackage.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXPackageItem.h"
#import "PEXPackageHumanDescription.h"
#import "PEXGuiTextView_Protected.h"


@interface PEXGuiPackageView ()

@property (nonatomic) PEXGuiClassicLabel * L_label;
@property (nonatomic) PEXGuiClassicLabel * L_description;

@end

@implementation PEXGuiPackageView {

}

- (void) applyPackage: (const PEXPackage * const) package
{
    PEXPackageHumanDescription * const human = [[PEXPackageHumanDescription alloc] init];
    [human applyPackage:package];

    self.L_label.text = human.shortLabel;
    if (package.productType == PEXPackageSubscription){
        self.L_description.text = PEXStr(@"L_product_type_subscription");
    } else if (package.productType == PEXPackageConsumable){
        self.L_description.text = PEXStr(@"L_product_type_consumable");
    } else {
        self.L_description.text = PEXStr(@"L_product_type_none");
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.L_description = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                      fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_description];

    self.L_label = [[PEXGuiClassicLabel alloc] init];
    [self addSubview:self.L_label];


    //self.TV_description = [[PEXGuiReadOnlyTextView alloc] init];


    //self.aliasView = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")];
    //[self addSubview:self.aliasView];

    return self;

}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.L_label];
    [PEXGVU scaleHorizontally:self.L_description withMargin:PEXVal(@"dim_size_medium")];

    self.L_label.frame = CGRectMake(PEXVal(@"dim_size_large"), self.L_label.frame.origin.y,
            self.frame.size.width, self.L_label.frame.size.height);
}


@end