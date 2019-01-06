//
// Created by Matej Oravec on 18/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPackageItemView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXPackage.h"
#import "PEXGuiReadOnlyTextView.h"


@interface PEXGuiPackageItemView()

@property (nonatomic) PEXGuiReadOnlyTextView * TV_label;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_description;

@end

@implementation PEXGuiPackageItemView {

}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.TV_label = [[PEXGuiReadOnlyTextView alloc] init];
    //self.TV_description = [[PEXGuiReadOnlyTextView alloc] init];

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.TV_label];
    self.TV_label.frame = CGRectMake([self staticHeight], self.TV_label.frame.origin.y,
            self.frame.size.width, self.TV_label.frame.size.height);
}


@end