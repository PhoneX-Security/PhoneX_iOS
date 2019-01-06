//
// Created by Matej Oravec on 09/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiPreferencesController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiLinearScrollingView.h"
#import "PEXGuiDetailView.h"

#import "PEXGuiChooseLanguageController.h"
#import "PEXChooseLanguageExecutor.h"

#import "PEXChooseThemeExecutor.h"
#import "PEXGuiProfileController.h"

#import "PEXGuiPinLockPrefController.h"
#import "PEXMessageArchiveExecutor.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiMessageArchiveSelectionController.h"
#import "PEXGuiFactory.h"
#import "PEXGuiBinaryDialogExecutor.h"
#import "PEXGuiTicker.h"
#import "PEXGuiPoint.h"
#import "PEXLoginHelper.h"
#import "PEXTouchId.h"
#import "PEXLicenceInfo.h"
#import "PEXReport.h"
#import "PEXMuteNotificationExecutor.h"
#import "PEXUtils.h"
#import "PEXGuiLoginController.h"
#import "PEXGuiPreferenceSubsectionEntry.h"
#import "PEXGuiPreferencesNotificationsController.h"

#import <LocalAuthentication/LocalAuthentication.h>

@interface PEXGuiPreferencesController () <PEXGuiDialogBinaryListener>

@property (nonatomic) NSLock * lock;

@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiDetailView * languageView;
@property (nonatomic) PEXGuiDetailView * themeView;
@property (nonatomic) PEXGuiPoint * lineFirst;
@property (nonatomic) PEXGuiDetailView * pinLockView;
@property (nonatomic) PEXGuiDetailView * touchIdLockView;
@property (nonatomic) PEXGuiPoint * lineSecond;
@property (nonatomic) PEXGuiDetailView * messageArchiveView;
@property (nonatomic) PEXGuiPreferenceSubsectionEntry *notificationsView;
@property (nonatomic) PEXGuiPoint * lineThird;
@property (nonatomic) PEXGuiTicker * allowHandsfree;
@property (nonatomic) PEXGuiTicker * showSipsInContactList;
@property (nonatomic) PEXGuiTicker * enableGoogleAnalytics;
// @property (nonatomic) PEXGuiTicker * savePassword;
@property (nonatomic) PEXGuiPoint * lineFourth;
@property (nonatomic) PEXGuiDetailView * logoutView;
@property (nonatomic) PEXGuiController * showedController;

@end

@implementation PEXGuiPreferencesController {

}

- (id) init
{
    self = [super init ];

    self.lock = [[NSLock alloc] init];

    return self;
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"Preferences";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{

        self.languageView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.languageView];

        self.themeView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.themeView];

        self.lineFirst = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineFirst];

        self.pinLockView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.pinLockView];

        self.touchIdLockView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.touchIdLockView];

        self.lineSecond = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineSecond];

        self.notificationsView = [[PEXGuiPreferenceSubsectionEntry alloc] init];
        [self.linearView addView:self.notificationsView];

        self.messageArchiveView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.messageArchiveView];

        self.lineThird = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineThird];

        self.allowHandsfree = [[PEXGuiTicker alloc] init];
        [self.linearView addView:self.allowHandsfree];

        self.showSipsInContactList = [[PEXGuiTicker alloc] init];
        [self.linearView addView:self.showSipsInContactList];

        self.enableGoogleAnalytics = [[PEXGuiTicker alloc] init];
        [self.linearView addView:self.enableGoogleAnalytics];

        /*
        self.savePassword = [[PEXGuiTicker alloc] init];
        [self.linearView addView:self.savePassword];
        */

        self.lineFourth = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.lineFourth];

        self.logoutView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.logoutView];

    }];
}


- (void) initContent
{
    [super initContent];

    [self.languageView setName:PEXStrU(@"L_language")];
    [self.themeView setName:PEXStrU(@"L_graphic_theme")];
    [self.pinLockView setName:PEXStrU(@"L_pin_lock")];
    [self.touchIdLockView setName:PEXStrU(@"L_touch_id")];
    [self.messageArchiveView setName:PEXStrU(@"L_message_archive")];
    [self.notificationsView setLabel:PEXStrU(@"L_notifications")];
    [self.allowHandsfree setLabel:PEXStr(@"L_allow_handsfree")];
    [self.showSipsInContactList setLabel:PEXStr(@"L_show_sips_in_contact_list")];
    [self.enableGoogleAnalytics setLabel:PEXStr(@"L_enable_google_analytics")];
    [self.logoutView setName:PEXStr(@"menu_logout")];
    [self.logoutView setValue:PEXStr(@"txt_logout_desc")];
    // [self.savePassword setLabel:PEXStr(@"L_save_password")];

    [self.lock lock];

    [[PEXAppPreferences instance] addListener:self];
    [self reload];

    [self.lock unlock];
}

- (void)preferenceChangedForKey:(NSString *const)key
{
    [self.lock lock];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self reload];
    });
    [self.lock unlock];
}

- (void) reload
{
    [self loadLanguage];
    [self loadTheme];
    [self loadPinLock];
    [self loadTouchId];
    [self loadMessageArchive];
    [self loadHandsfreeDefault];
    [self loadShowSipsInContactList];
    [self loadSavePassword];
    [self loadEnableGoogleAnalytics];
}

- (void) loadLanguage
{
    [self.languageView setValue: [_PEXStr getLanguageDescription:
            [[PEXAppPreferences instance]
                    getStringPrefForKey:PEX_PREF_APPLICATION_LANGUAGE_KEY defaultValue:PEX_LANGUAGE_SYSTEM]]];
}

- (void) loadTheme
{
    [self.themeView setValue: [PEXTheme getThemeDescription:
            [[PEXAppPreferences instance] getIntPrefForKey:PEX_PREF_GUI_THEME_KEY
                                              defaultValue:PEX_THEME_LIGHT]]];
}

- (void) loadPinLock
{
    [self.pinLockView setValue: ([[PEXUserAppPreferences instance] getStringPrefForKey: PEX_PREF_PIN_LOCK_PIN_KEY
                                                                     defaultValue:nil] ?

                                 [NSString stringWithFormat:@"%@: %@",PEXStr(@"L_on"),
                                  [PEXGuiPinLockPrefController getTriggerTimeDescription:
                                          [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_KEY
                                                                                defaultValue:PEX_PREF_PIN_LOCK_TRIGGER_TIME_SECONDS_DEFAULT]]] :

                                 PEXStr(@"L_off"))];
}

- (void) loadTouchId
{
    const PEXTouchIdStatus status = [PEXTouchId getTouchIdStatus];

    NSString * valueMessage = nil;

    switch (status)
    {
        case TOUCH_ID_STATUS_IOS8_PLUS_NEEDED:
            valueMessage = PEXStr(@"L_touch_id_ios8plus_required");
            break;

        case TOUCH_ID_STATUS_NOT_USED:
            valueMessage = [[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY
                                                                    defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT] ?
                    PEXStr(@"L_touch_id_not_used") :
                    PEXStr(@"txt_touch_id_pinlock_not_set");
            break;

        case TOUCH_ID_STATUS_SET_AND_USED:
            valueMessage = PEXStr(@"L_touch_id_set_and_used");
            break;

        default:
            //case TOUCH_ID_STATUS_NOT_AVAILABLE:
            valueMessage = PEXStr(@"L_touch_id_not_available");
            break;
    }

    [self.touchIdLockView setValue:valueMessage];
}

- (void) loadMessageArchive
{
    NSNumber * const value = [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY
                                                                      defaultValue:PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT];

    [self.messageArchiveView setValue:
            [PEXGuiMessageArchiveSelectionController getTriggerTimeDescriptionFromSeconds:value]];
}

- (void)loadHandsfreeDefault
{
    [self.allowHandsfree setChecked:
            [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_APPLICATION_DEFAULT_HANDSFREE
                                                   defaultValue:PEX_PREF_APPLICATION_DEFAULT_HANDSFREE_DEFAULT]];
}

- (void) loadShowSipsInContactList
{
    [self.showSipsInContactList setChecked:
            [[PEXUserAppPreferences instance] getBoolPrefForKey: PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY
                                                   defaultValue: PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_DEFAULT]];
}

- (void)loadEnableGoogleAnalytics
{
    [self.enableGoogleAnalytics setChecked:[PEXReport googleAnalyticsEnabledStatus]];
}

- (void) loadSavePassword
{
    // DEPRECATED See IPH-294
    /*
    const bool value = [[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY
    defaultValue: PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT];

    [self.savePassword setChecked:value];
    */
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.languageView];
    [PEXGVU scaleHorizontally:self.themeView];
    [PEXGVU scaleHorizontally:self.pinLockView];
    [PEXGVU scaleHorizontally:self.touchIdLockView];
    [PEXGVU scaleHorizontally:self.notificationsView];
    [PEXGVU scaleHorizontally:self.messageArchiveView];

    [PEXGVU scaleHorizontally:self.lineFirst];
    [PEXGVU scaleHorizontally:self.lineSecond];
    [PEXGVU scaleHorizontally:self.lineThird];
    [PEXGVU scaleHorizontally:self.lineFourth];

    [PEXGVU scaleHorizontally:self.allowHandsfree];
    [PEXGVU scaleHorizontally:self.showSipsInContactList];
    [PEXGVU scaleHorizontally:self.enableGoogleAnalytics];
    [PEXGVU scaleHorizontally:self.logoutView];
    // [PEXGVU scaleHorizontally:self.savePassword];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.languageView addAction:self action:@selector(showChooseLanguage)];
    [self.themeView addAction:self action:@selector(showChooseTheme)];
    [self.pinLockView addAction:self action:@selector(showPinLock)];
    [self.touchIdLockView addAction:self action:@selector(processTouchId)];

    [self.notificationsView addAction:self action:@selector(showNotificationsInternal)];
    [self.messageArchiveView addAction:self action:@selector(showMessageArchive)];

    [self.allowHandsfree addAction:self action:@selector(showHandsfreeDefault)];
    [self.showSipsInContactList addAction:self action:@selector(showShowSipsInContactList)];
    [self.enableGoogleAnalytics addAction:self action:@selector(changeEnableGoogleAnalytics)];
    [self.logoutView addAction:self action:@selector(showLogoutPrompt)];
    // [self.savePassword addAction:self action:@selector(showSavePassword)];


}

- (void) showChooseLanguage
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_CHOOSE_LANGUAGE];
    PEXChooseLanguageExecutor * const executor = [[PEXChooseLanguageExecutor alloc]
                                               initWithParentController:self];
    [executor show];
}

- (void) showChooseTheme
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_CHOOSE_THEME];
    PEXChooseThemeExecutor * const executor = [[PEXChooseThemeExecutor alloc]
                                                  initWithParentController:self];
    [executor show];
}


- (void) showPinLock
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_PIN_LOCK];
    [PEXGAU showInNavigation:[[PEXGuiPinLockPrefController alloc] init]
                          in:self
                       title:PEXStrU(@"L_pin_lock")];
}

- (void) showMessageArchiveInternal
{
    PEXMessageArchiveExecutor * const executor = [[PEXMessageArchiveExecutor alloc] initWithParentController:self];
    [executor show];
}

- (void) showMessageArchive
{
    WEAKSELF;
    // if was set OFF
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_MESSAGE_ARCHIVE];
    if (![[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY
                                                 defaultValue:PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT])
    {
        PEXGuiBinaryDialogExecutor * const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
        executor.primaryButtonText = PEXStrU(@"B_continue");
        executor.secondaryButtonText = PEXStrU(@"B_cancel");
        executor.text = PEXStr(@"txt_message_archivation_is_dangerous");

        executor.primaryAction = ^{
            [weakSelf showMessageArchiveInternal];
        };

        [executor show];
    }
    else
    {
        [weakSelf showMessageArchiveInternal];
    }
}

- (void) showNotificationsInternal
{
    [PEXGAU showInNavigation:[[PEXGuiPreferencesNotificationsController alloc] init]
                          in:self
                       title:PEXStrU(@"menu_notifications")];
}

- (void)showHandsfreeDefault
{
    const bool isCHecked = [self.allowHandsfree isChecked];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_APPLICATION_DEFAULT_HANDSFREE
                                                      value:!isCHecked];

    });
}

- (void)showShowSipsInContactList
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_SHOW_USER_NAME];
    const bool isCHecked = [self.showSipsInContactList isChecked];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_SHOW_SIP_IN_CONTACT_LIST_KEY
                                                      value:!isCHecked];

    });
}

- (void)changeEnableGoogleAnalytics
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_ENABLE_GOOGLE_ANALYTICS];
    const bool isCHecked = [self.enableGoogleAnalytics isChecked];
    const bool forcedOn = [PEXReport googleAnalyticsForceEnabled];
    if (forcedOn){
        dispatch_async(dispatch_get_main_queue(), ^{
            [PEXGuiFactory showErrorTextBox:self
                                   withText:PEXStr(@"txt_cannot_disable_gai")];
        });
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PEXReport setGoogleAnalyticsEnabledByUser:!isCHecked];
        [PEXReport checkGoogleAnalyticsEnabledStatus];
    });
}

- (void)showSavePassword
{
    // if was set ON

    // DEPRECATED See IPH-294

    /*
    if ([[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY
                                                  defaultValue:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT])
    {
        PEXGuiBinaryDialogExecutor * const executor = [[PEXGuiBinaryDialogExecutor alloc] initWithController:self];
        executor.primaryButtonText = PEXStrU(@"B_turn_off");
        executor.secondaryButtonText = PEXStrU(@"B_cancel");
        executor.text = [NSString stringWithFormat:@"%@\n\n%@",
                        PEXStr(@"txt_turn_off_save_password"), PEXStr(@"txt_q_really_turn_off")];

        executor.primaryAction = ^{
            [self checkSavePassword];
        };

        [executor show];
    }
    else
    {
        [self checkSavePassword];
    }
    */
}

- (void) checkSavePassword
{
    /*
    const bool value = ![self.savePassword isChecked];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        [PEXLoginHelper setSavePasswordInKeyChain:value];
    });
    */
}

- (void) showLogoutPrompt{
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOGOUT];
    self.showedController = [PEXGuiFactory showBinaryDialog:self
                                                   withText:PEXStr(@"msg_logout_question")
                                                   listener:self
                                              primaryAction:PEXStrU(@"menu_logout") secondaryAction:nil];
}

- (void) secondaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOGOUT_CANCEL];
    [self hideLogout:nil];
}

- (void) primaryButtonClicked
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_LOGOUT_CONFIRM];
    [self hideLogout:^{
        [[PEXGuiLoginController instance] performLogout];
    }];
}

- (void) hideLogout: (void (^) (void)) completion
{
    [self.showedController dismissViewControllerAnimated:true completion:completion];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {

    [self.lock lock];

    [[PEXAppPreferences instance] removeListener:self];

    [self.lock unlock];

    [super dismissViewControllerAnimated:flag completion:completion];
}

- (void)processTouchId {

    const PEXTouchIdStatus status = [PEXTouchId getTouchIdStatus];

    NSString *dialogMessage = nil;

    [PEXReport logUsrButton:PEX_EVENT_BTN_PREFS_TOUCH_ID];
    switch (status)
    {
        case TOUCH_ID_STATUS_IOS8_PLUS_NEEDED:
            dialogMessage = PEXStr(@"txt_touch_id_ios8plus_required_message");
            break;

        case TOUCH_ID_STATUS_NOT_AVAILABLE:
            dialogMessage = PEXStr(@"txt_touch_id_not_available_message");
            break;

        case TOUCH_ID_STATUS_NOT_USED:

            if (![[PEXUserAppPreferences instance] getStringPrefForKey:PEX_PREF_PIN_LOCK_PIN_KEY
                                                       defaultValue:PEX_PREF_PIN_LOCK_PIN_DEFAULT])
            {
                dialogMessage = PEXStr(@"txt_touch_id_pinlock_not_set_message");
            }
            else
            {
                [[PEXTouchId instance] requestTouchIdWithMessageAsync:PEXStr(@"txt_touch_id_verify_to_set")
                                                            onSuccess:^{
                                                                [PEXTouchId setByUserInApp:true];
                                                            }
                                                            onFailure:nil];
            }

            break;

        case TOUCH_ID_STATUS_SET_AND_USED:
            [PEXTouchId setByUserInApp:false];
            break;
    }

    if (dialogMessage)
    {
        [PEXGuiFactory showWarningTextBox:self withText:dialogMessage];
    }
}

- (void)touchIdMisc
{
    LAContext *myContext = [[LAContext alloc] init];
    NSError *authError = nil;
    NSString *myLocalizedReasonString = @"Touch ID Test to show Touch ID working in a custom app";

    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&authError]) {
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                  localizedReason:myLocalizedReasonString
                            reply:^(BOOL success, NSError *error) {
                                if (success) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        //[self performSegueWithIdentifier:@"Success" sender:nil];
                                    });
                                } else {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                            message:error.description
                                                                                           delegate:self
                                                                                  cancelButtonTitle:@"OK"
                                                                                  otherButtonTitles:nil, nil];
                                        [alertView show];
                                        // Rather than show a UIAlert here, use the error to determine if you should push to a keypad for PIN entry.
                                    });
                                }
                            }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:authError.description
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
            [alertView show];
            // Rather than show a UIAlert here, use the error to determine if you should push to a keypad for PIN entry.
        });
    }
}

@end