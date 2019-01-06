//
// Created by Matej Oravec on 18/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiThumailView.h"


@implementation PEXGuiThumailView {

}

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.contentMode = UIViewContentModeCenter;
    if (self.image.size.width > self.frame.size.width ||
            self.image.size.height > self.frame.size.height) {
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
}

@end