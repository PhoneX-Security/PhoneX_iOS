//
// Created by Matej Oravec on 09/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiGetPremiumController.h"

#import "PEXGuiController_Protected.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiBackgroundView.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiButtonMain.h"
#import "PEXDbContact.h"
#import "PEXGuiChatController.h"
#import "PEXGuiLoginController.h"
#import "PEXReport.h"

@interface PEXGuiGetPremiumController ()

@property (nonatomic) PEXGuiClickableScrollView * V_scroller;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_prologue;

@property (nonatomic) PEXGuiBackgroundView * V_businessBackground;
@property (nonatomic) UILabel * L_businessLabel;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_businessDetail;

@property (nonatomic) PEXGuiBackgroundView * V_personalBackground;
@property (nonatomic) UILabel * L_personalLabel;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_personalDetail;

@property (nonatomic) PEXGuiReadOnlyTextView * TV_areYouInterested;
@property (nonatomic) UIButton * B_goToWeb;
@property (nonatomic) UIButton *B_contactSupport;

@property (nonatomic) PEXDbContact * supportContact;

@property (nonatomic) NSString * message;

@end

@implementation PEXGuiGetPremiumController {

}

- (id) initWithMessage: (NSString * const) message
{
    self = [super init];

    self.message = message;

    return self;
}

- (id) init
{
    return [self initWithMessage:PEXStr(@"txt_premium_general_info")];
}

- (void)initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"GetPremium";

    self.V_scroller = [[PEXGuiClickableScrollView alloc] init];
    [self.mainView addSubview:self.V_scroller];

    self.TV_prologue = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_scroller addSubview:self.TV_prologue];

    // business

    self.V_businessBackground = [[PEXGuiBackgroundView alloc] initWithColor:PEXCol(@"light_orange_normal")];
    [self.V_scroller addSubview: self.V_businessBackground];

    self.L_businessLabel = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self.V_businessBackground addSubview:self.L_businessLabel];

    self.TV_businessDetail = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_businessBackground addSubview:self.TV_businessDetail];

    // personal

    self.V_personalBackground = [[PEXGuiBackgroundView alloc] initWithColor:PEXCol(@"light_orange_normal")];
    [self.V_scroller addSubview: self.V_personalBackground];

    self.L_personalLabel = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_medium")
                   fontColor:PEXCol(@"light_gray_low")];
    [self.V_personalBackground addSubview:self.L_personalLabel];

    self.TV_personalDetail = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_personalBackground addSubview:self.TV_personalDetail];

    self.TV_areYouInterested = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_scroller addSubview:self.TV_areYouInterested];

    // action

    self.B_goToWeb = [[PEXGuiButtonMain alloc] init];
    [self.V_scroller addSubview:self.B_goToWeb];

    [self readSupportContact];

    if (self.supportContact)
    {
        self.B_contactSupport = [[PEXGuiButtonMain alloc] init];
        [self.V_scroller addSubview:self.B_contactSupport];
    }
}

- (void) readSupportContact
{
    NSString * const supportSip =
            [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_SUPPORT_CONTACT_SIP_KEY
                                                     defaultValue:PEX_PREF_SUPPORT_CONTACT_SIP_DEFAULT];

    if (supportSip)
    {
        PEXDbCursor * const cursor = [[PEXDbAppContentProvider instance]
                                            query:[PEXDbContact getURI]
                                       projection:[PEXDbContact getLightProjection]
                                        selection:[PEXDbContact getWhereForSip]
                                    selectionArgs:[PEXDbContact getWhereForSipArgs:supportSip]
                                        sortOrder:nil];

        if (cursor && [cursor moveToNext])
        {
            self.supportContact = [PEXDbContact contactFromCursor:cursor];
        }
    }
}

- (void)initContent
{
    [super initContent];

    self.TV_prologue.text = PEXStr(@"txt_get_premium_prologue");

    self.L_businessLabel.text = PEXStrU(@"L_business_licence");
    self.TV_businessDetail.text = PEXStr(@"L_business_licence_detail");
    self.TV_businessDetail.backgroundColor = PEXCol(@"invisible");

    self.L_personalLabel.text = PEXStrU(@"L_personal_licence");
    self.TV_personalDetail.text = PEXStr(@"L_personal_licence_detail");
    self.TV_personalDetail.backgroundColor = PEXCol(@"invisible");

    self.TV_areYouInterested.text = PEXStr(@"L_get_premium_are_you_interested");

    [self.B_goToWeb setTitle:PEXStrU(@"B_go_to_web") forState:UIControlStateNormal];

    if (self.B_contactSupport)
        [self.B_contactSupport setTitle:PEXStrU(@"B_contact_support") forState:UIControlStateNormal];
}

- (void)initBehavior
{
    [self.B_goToWeb addTarget:self action:@selector(goToWeb:) forControlEvents:UIControlEventTouchUpInside];

    if (self.B_contactSupport)
        [self.B_contactSupport addTarget:self action:@selector(contactSupport:) forControlEvents:UIControlEventTouchUpInside];

    [self.TV_areYouInterested setScrollEnabled:false];
    [self.TV_businessDetail setScrollEnabled:false];
    [self.TV_personalDetail setScrollEnabled:false];
    [self.TV_prologue setScrollEnabled:false];

    [super initBehavior];
}

- (IBAction) goToWeb: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREMIUM_WEB];
    NSURL * const url = [NSURL URLWithString:@"http://www.phone-x.net/solution"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)contactSupport: (id) contactSupport
{
    // TODO GARBAGE
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREMIUM_SUPPORT];
    UIViewController * const parent = [[PEXGuiLoginController instance] landingController];
    UIViewController * candidate = self.fullscreener;

    while (candidate.parentViewController)
    {
        if (candidate.parentViewController != parent)
            candidate = candidate.parentViewController;
        else
            break;
    }

    if ([parent.childViewControllers containsObject:candidate])
    {
        [candidate dismissViewControllerAnimated:true completion:^{
            [PEXGuiChatController showChatInNavigation:parent withContact:self.supportContact];
        }];
    }
    else
    {
        DDLogDebug(@"Unable to show Chat with support!");
    }

}

- (void)initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.V_scroller];

    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat margin = PEXVal(@"dim_size_large");
    const CGFloat componentWidth = width - (2 * margin);

    [PEXGVU scaleHorizontally:self.TV_prologue];
    [self.TV_prologue sizeToFit];
    [PEXGVU moveToTop:self.TV_prologue];

    // business
    [PEXGVU scaleHorizontally:self.V_businessBackground];
    [PEXGVU move:self.V_businessBackground below:self.TV_prologue];

    [PEXGVU moveToTop:self.L_businessLabel withMargin:margin];
    [PEXGVU moveToLeft:self.L_businessLabel withMargin:margin];

    [PEXGVU scaleHorizontally:self.TV_businessDetail];
    [self.TV_businessDetail sizeToFit];
    [PEXGVU move:self.TV_businessDetail below:self.L_businessLabel];

    [PEXGVU setHeight:self.V_businessBackground to:[PEXGVU getLowerPoint:self.TV_businessDetail]];

    // personal

    [PEXGVU scaleHorizontally:self.V_personalBackground];
    [PEXGVU move:self.V_personalBackground below:self.V_businessBackground withMargin:margin];

    [PEXGVU moveToTop:self.L_personalLabel withMargin:margin];
    [PEXGVU moveToLeft:self.L_personalLabel withMargin:margin];

    [PEXGVU scaleHorizontally:self.TV_personalDetail];
    [self.TV_personalDetail sizeToFit];
    [PEXGVU move:self.TV_personalDetail below:self.L_personalLabel];

    [PEXGVU setHeight:self.V_personalBackground to:[PEXGVU getLowerPoint:self.TV_personalDetail]];

    // actiob

    [PEXGVU scaleHorizontally:self.TV_areYouInterested];
    [self.TV_areYouInterested sizeToFit];
    [PEXGVU move:self.TV_areYouInterested below:self.V_personalBackground];

    [PEXGVU scaleHorizontally:self.B_goToWeb withMargin:margin];
    [PEXGVU move:self.B_goToWeb below:self.TV_areYouInterested];

    if (self.B_contactSupport)
    {
        [PEXGVU scaleHorizontally:self.B_contactSupport withMargin:margin];
        [PEXGVU move:self.B_contactSupport below:self.B_goToWeb withMargin:margin];
    }

    self.V_scroller.contentSize =
            CGSizeMake(self.mainView.frame.size.width,
                    [PEXGVU getLowerPoint:(self.B_contactSupport ?
                            self.B_contactSupport :
                            self.B_goToWeb)] + margin);
}

@end