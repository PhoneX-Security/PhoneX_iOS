//
// Created by Matej Oravec on 30/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiCircleView.h"

@interface PEXGuiCircleView ()

@property (nonatomic) UIColor * color;

@end

@implementation PEXGuiCircleView {

}

- (id) init
{
    return [self initWithDiameter:PEXVal(@"dim_size_medium")];
}

- (id) initWithDiameter: (const CGFloat) diameter
{
    self = [super initWithFrame:CGRectMake(0,0,diameter,diameter)];
    self.layer.cornerRadius = diameter / 2.0f;
    self.backgroundColor = PEXCol(@"black_normal");
    return self;
}


@end