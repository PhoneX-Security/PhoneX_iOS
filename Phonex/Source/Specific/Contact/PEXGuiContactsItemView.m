//
//  PEXGuiContactsItemView.m
//  Phonex
//
//  Created by Matej Oravec on 22/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiContactsItemView.h"


#import "PEXGuiContactsItemView_Protected.h"

#import "PEXDbContact.h"
#import "PEXGuiClassicLabel.h"
#import "PEXUser.h"

#import "PEXPbPush.pb.h"

@interface PEXGuiContactsItemView ()
{
@private bool _showUsername;
}

@end

@implementation PEXGuiContactsItemView

- (void) initGui
{
    _showUsername = true;

    self.aliasView = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_medium")];
    [self addSubview:self.aliasView];

    self.usernameView = [[PEXGuiClassicLabel alloc] initWithFontSize:PEXVal(@"dim_size_small_medium")
                                                               fontColor:PEXCol(@"light_gray_low")];
    [self addSubview:self.usernameView];

    self.statusView = [[PEXGuiPresenceView alloc] init];
    [self addSubview:self.statusView];
}

- (void) applyContact:  (const PEXDbContact * const) contact
{
    if (![self.aliasView.text isEqualToString:contact.displayName])
        self.aliasView.text = contact.displayName;
    if (self.usernameView && ![self.usernameView.text isEqualToString:contact.sip])
        self.usernameView.text = contact.sip;

    // cannot be checked
    [self.statusView setPresence:[contact.presenceStatusType integerValue]];
}

- (void) setShowUsername: (const bool) showUsername
{
    if (_showUsername != showUsername)
    {
        _showUsername = showUsername;
        [self.usernameView setHidden:!_showUsername];
        [self adjustUsername];
    }
}

// according to applyContact
+ (bool) contact: (const PEXDbContact * const) c1
     needsUpdate: (const PEXDbContact * const) c2
{
    if (![c1.presenceStatusType isEqualToNumber: c2.presenceStatusType]) return true;
    if (![c1.displayName isEqualToString: c2.displayName]) return true;
    if (![c1.sip isEqualToString: c2.sip]) return true;

    return false;
}

+ (void) copyContactFrom: (const PEXDbContact * const) c2
                     to: (PEXDbContact * const) c1
{
    c1.presenceStatusType = c2.presenceStatusType;
    c1.displayName = c2.displayName;
    c1.sip = c2.sip;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [PEXGVU centerVertically:self.statusView];

    const CGFloat margin = [self getMargin];
    [PEXGVU moveToLeft:self.statusView
            withMargin:margin];


    [PEXGVU scaleHorizontally:self.aliasView from:self.statusView
                   leftMargin:margin rightMargin:PEXVal(@"dim_size_large")];

    if (_showUsername)
    {
        [PEXGVU moveAboveCenter:self.aliasView];
        [PEXGVU moveBelowCenter:self.usernameView];
        [PEXGVU scaleHorizontally:self.usernameView from:self.statusView
                       leftMargin:margin rightMargin:PEXVal(@"dim_size_large")];
    }
    else
    {
        [PEXGVU centerVertically:self.aliasView];
    }
}

- (CGFloat) getMargin
{
    return ([self staticHeight] - self.statusView.frame.size.width) / 2;
}

- (void) adjustUsername
{
    if (_showUsername)
    {
        [PEXGVU moveAboveCenter:self.aliasView];
        [PEXGVU moveBelowCenter:self.usernameView];
        [PEXGVU scaleHorizontally:self.usernameView from:self.statusView
                       leftMargin:[self getMargin] rightMargin:PEXVal(@"dim_size_large")];
    }
    else
    {
        [PEXGVU centerVertically:self.aliasView];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
