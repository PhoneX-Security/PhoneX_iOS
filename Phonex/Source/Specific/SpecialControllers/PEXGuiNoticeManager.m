//
//  PEXGuiNoticeManager.m
//  Phonex
//
//  Created by Matej Oravec on 12/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiNoticeManager.h"

#import "PEXGuiLoginController.h"
#import "PEXGuiFactory.h"

#import "PEXGuiSpecialPriorityManager.h"

#import "PEXGuiTextController.h"
#import "PEXGuiDialogBinaryVisitor.h"

#import "PEXVersionChecker.h"
#import "PEXAppVersionUtils.h"

@interface PEXGuiNoticeManager ()
{
    @private uint64_t _noticedVersionCode;
}

@property (nonatomic) NSLock * lock;
@property (nonatomic) PEXGuiController * showedNoticeController;

@end

@implementation PEXGuiNoticeManager


- (void) bringToFront
{
    [self.lock lock];

    if (self.showedNoticeController)
    {
        [self.showedNoticeController.parentViewController.view bringSubviewToFront:self.showedNoticeController.view];
    }

    [self.lock unlock];
}

- (void) reshowNoticeIfNeeded
{
    [self.lock lock];
    if (self.showedNoticeController)
    {
        [self dismissInternal];
        [self showInternal];
    }
    [self.lock unlock];

    [PEXGuiSpecialPriorityManager reorder];
}

- (void) showNotice: (const uint64_t) noticedVersionCode
{
    [self.lock lock];

    if (!self.showedNoticeController)
    {
        _noticedVersionCode = noticedVersionCode;
        [self showInternal];

    }

    [self.lock unlock];

    [PEXGuiSpecialPriorityManager reorder];
}

- (void) showInternal
{
    PEXGuiLoginController * const loginController = [PEXGuiLoginController instance];
    UIViewController * const parent = [loginController landingController] ? [loginController landingController] : loginController;

    NSString * const yourVersionString = [PEXAppVersionUtils fullVersionString];
    NSString * const yourVersionText = [NSString stringWithFormat:@"%@: %@",
                    PEXStr(@"L_your_version"), yourVersionString];

    NSString * newVersionString = [PEXAppVersionUtils codeToFullVersionString:_noticedVersionCode];

    if ([yourVersionString isEqualToString:newVersionString])

    {
        // we are logged
        if ([loginController landingController] &&
                [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_SHOW_THANK_YOU_KEY
                                                       defaultValue:PEX_PREF_SHOW_THANK_YOU_DEFAULT]
        )
        {
            self.showedNoticeController = [PEXGuiFactory showTextBox:parent withText:
                    [NSString stringWithFormat:@"%@ \r\n\r\n%@", PEXStr(@"txt_thanks_for_using"), yourVersionText]];
            [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_SHOW_THANK_YOU_KEY
                                                          value:false];
        }
    }
    else
    {
        NSString * const newVersionText = [NSString stringWithFormat:@"%@: %@",
                        PEXStr(@"L_new_version"), newVersionString];

        NSString *const mainText = PEXStr(@"txt_new_version_available");
        NSString *const completeText = [NSString stringWithFormat:@"%@ \r\n\r\n%@ \r\n%@",
                                                                  mainText, yourVersionText, newVersionText];

        self.showedNoticeController = [PEXGuiFactory showBinaryDialog:parent
                                                             withText:completeText
                                                             listener:self
                                                        primaryAction:PEXStrU(@"B_update") secondaryAction:PEXStrU(@"B_later")];

        if ([loginController landingController])
        {
            [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_SHOW_THANK_YOU_KEY
                                                          value:true];
        }
    }
}

- (void) primaryButtonClicked
{
    [PEXVersionChecker openUpdateWindow];
    [self dismissNoticeFromDialog];
}

- (void) secondaryButtonClicked
{
    [PEXVersionChecker updateLater:_noticedVersionCode];
    [self dismissNoticeFromDialog];
}

- (void) dismissNoticeFromDialog
{
    [self.lock lock];

    [self dismissInternal];
    _noticedVersionCode = 0;
    self.showedNoticeController = nil;

    [self.lock unlock];
}

- (void) dismissNoticeFromOutside
{
    [self.lock lock];

    [self dismissInternal];

    [self.lock unlock];
}

- (void) dismissInternal
{
    if (self.showedNoticeController)
    {
        [self.showedNoticeController dismissViewControllerAnimated:true completion:nil];
    }
}

+ (PEXGuiNoticeManager *) instance
{
    static PEXGuiNoticeManager * instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[PEXGuiNoticeManager alloc] init];
    });

    return instance;
}

- (id) init
{
    self = [super init];

    _noticedVersionCode = 0;

    return self;
}

@end
