//
// Created by Matej Oravec on 07/04/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileViewCell.h"
#import "PEXGuiFileView.h"
#import "PEXGuiActivityIndicatorView.h"

@interface PEXGuiFileViewCell ()

@property (nonatomic) PEXGuiFileView * fileView;

@end

@implementation PEXGuiFileViewCell {

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    self.fileView = [[PEXGuiFileView alloc] init];
    [self.fileView initGui];

    [self.contentView addSubview:self.fileView];

    self.backgroundColor = PEXCol(@"white_normal");

    return self;
}

- (PEXGuiFileView *) getFileView
{
    return self.fileView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU scaleFull:self.contentView];
    [PEXGVU scaleFull:self.fileView];
}

@end