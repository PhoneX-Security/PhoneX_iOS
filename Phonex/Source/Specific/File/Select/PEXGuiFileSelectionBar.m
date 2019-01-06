//
//  PEXGuiSelectioBar.m
//  Phonex
//
//  Created by Matej Oravec on 23/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiFileSelectionBar.h"
#import "PEXGuiSelectionBar_Protected.h"

#import "PEXGuiImageView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiFileUtils.h"
#import "PEXFilePickManager.h"
#import "PEXFileSelectRestrictor.h"

@interface PEXGuiFileSelectionBar ()

@property (nonatomic) UIView * I_deleteSelection;

@property (nonatomic) PEXGuiClassicLabel * L_secondaryRestriction;
@property (nonatomic, copy) void (^restrictionLayouter)(void);

@end

@implementation PEXGuiFileSelectionBar

- (id) init
{
    self = [super init];

    self.B_deleteSelection  = [[PEXGuiClickableView alloc] init];
    [self addSubview:self.B_deleteSelection];
    self.I_deleteSelection = [[PEXGuiImageView alloc] initWithImage:PEXImg(@"trash")];
    [self.B_deleteSelection addSubview:self.I_deleteSelection];

    [self bringSubviewToFront:self.V_disabler];

    self.L_secondaryRestriction = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                                   fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.L_secondaryRestriction];

    [self setPrimaryLayouter];

    return self;
}

- (void) setPrimaryLayouter
{
    WEAKSELF;
    self.restrictionLayouter = ^{
        [weakSelf layoutOnlyPrimaryrestriction];
    };
}

- (void) setBothLayouter
{
    WEAKSELF;
    self.restrictionLayouter = ^{
        [weakSelf layoutBothRestrictions];
    };
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    const CGFloat padding = PEXVal(@"dim_size_large");
    const CGFloat halfPadding = padding / 2.0f;
    const CGFloat paddingWidth = padding * 1.5f;

    [PEXGVU scaleVertically:self.B_deleteSelection];
    [PEXGVU setWidth:self.B_deleteSelection
                  to:self.I_deleteSelection.frame.size.width + padding];
    [PEXGVU move:self.B_deleteSelection rightOf:self.B_clearSelection];
    [PEXGVU center:self.I_deleteSelection];

    self.restrictionLayouter();
}

- (void) layoutBothRestrictions
{
    [PEXGVU moveAboveCenter:self.L_primaryRestriction];
    [PEXGVU moveBelowCenter:self.L_secondaryRestriction];

    [self.L_secondaryRestriction setHidden:false];
}

- (void) layoutOnlyPrimaryrestriction
{
    [PEXGVU centerVertically:self.L_primaryRestriction];

    [self.L_secondaryRestriction setHidden:true];
}

- (void) notifyError
{
    [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
        self.backgroundColor = PEXCol(@"red_normal");

    } completion:^(BOOL finished){
        [UIView animateWithDuration:PEXVal(@"dur_shorter") animations:^{
            self.backgroundColor = self.bgColor;
        }];
    }];
}

- (void)setSecondaryLabelText: (NSString * const) text
{
    [self setText:text forLabel:self.L_primaryRestriction];
}

- (void) setRestrictionDescription: (const PEXSelectionDescriptionInfo * const) restrictionDescription
                          forLabel: (UILabel * const) label
{
    [self setText:restrictionDescription.textDescription forLabel:label];

    label.textColor = (restrictionDescription.overlaps != PEX_SELECTION_DESC_STATUS_OK) ?
            PEXCol(@"orange_low") :
            PEXCol(@"light_gray_low");

}

// TODO ... currnetly takes only 2 restrictions ... or shows
- (void) setRestrictions: (NSArray * const) descriptors
{
    dispatch_async(dispatch_get_main_queue(), ^{

    // TODO hide on nil?
    switch (descriptors.count)
    {
        case 1:
            [self setRestrictionDescription:descriptors[0] forLabel:self.L_primaryRestriction];
            [self setPrimaryLayouter];
            [self layoutOnlyPrimaryrestriction];
            [self setEnabled:true];
            break;

        case 2:
            [self setRestrictionDescription:descriptors[0] forLabel:self.L_primaryRestriction];
            [self setRestrictionDescription:descriptors[1] forLabel:self.L_secondaryRestriction];
            [self setBothLayouter];
            [self layoutBothRestrictions];
            [self setEnabled:false];
            break;

        default:
            [self setEnabled:false];
    }

    [self setEnabled:true];
    });
}

@end
