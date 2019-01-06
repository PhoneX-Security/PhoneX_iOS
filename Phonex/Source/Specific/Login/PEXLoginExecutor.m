//
//  PEXLoginExecutor.m
//  Phonex
//
//  Created by Matej Oravec on 20/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXLoginExecutor.h"

#import "PEXGuiLoginProgressController.h"
#import "PEXLoginTask.h"
#import "PEXGuiWindowController.h"
#import "PEXCredentials.h"
#import "PEXGuiDialogProgressCanceller.h"
#import "PEXGuiFactory.h"
#import "PEXUser.h"
#import "PEXDatabase.h"
#import "PEXLoginTaskResult.h"
#import "PEXGuiSetNewPasswordExecutor.h"
#import "PEXUnmanagedObjectHolder.h"
#import "PEXGuiTabContainer.h"
#import "PEXGuiTabController.h"
#import "PEXPreferenceChangedListener.h"
#import "PEXGuiPresenceCenter.h"
#import "PEXGuiContactControllerList.h"
#import "PEXGuiImageView.h"
#import "PEXGuiChatsController.h"
#import "PEXGuiMainTabController.h"
#import "PEXGuiPreferencesController.h"
#import "PEXGuiNotificationCounterView.h"
#import "PEXGuiTabView.h"
#import "PEXGuiNotifiedTabView.h"
#import "PEXGuiCallsController.h"
#import "PEXGuiCallManager.h"
#import "PEXGuiPinLockManager.h"

#import "PEXGuiMessageNotifiedTabView.h"
#import "PEXGuiCallLogNotifiedTabView.h"

#import "PEXGuiShieldManager.h"

#import "PEXGuiLoginController.h"
#import "PEXSipUri.h"
#import "PEXGuiFileUtils.h"

#import "PEXGuiNoticeManager.h"
#import "PEXUserUpdater.h"
#import "PEXMessageArchiver.h"
#import "PEXGuiProfileController.h"
#import "PEXGuiProfileUpdateNotifiedTabView.h"
#import "PEXChatsManager.h"
#import "PEXCallsManager.h"
#import "PEXChatAccountingManager.h"
#import "PEXLicenceCheckTask.h"
#import "hr.h"
#import "PEXReferenceTimeManager.h"
#import "PEXLoginHelper.h"
#import "PEXContactNotificationManager.h"
#import "PEXGuiContactsNotifiedTabView.h"
#import "PEXCallLogManager.h"
#import "PEXLicenceManager.h"
#import "PEXLogsUtils.h"
#import "PEXReport.h"
#import "PEXGuiTuningController.h"
#import "PEXUtils.h"
#import "PEXPermissionsUtils.h"
#import "PEXService.h"
#import "PEXVersionChecker.h"

// TODO templateable
@interface PEXLoginExecutor ()

@property (nonatomic) PEXGuiController * parentController;
@property (nonatomic) PEXGuiController * updateController;
@property (nonatomic) const PEXCredentials * credentials;

@end

@implementation PEXLoginExecutor

- (id) initWithCredentials: (const PEXCredentials * const) credentials
          parentController: (PEXGuiController * const) parentController
{
    self = [super init];

    self.credentials = credentials;
    self.parentController = parentController;

    return self;
}

- (void) show
{
    PEXGuiProgressController * const progress = [[PEXGuiLoginProgressController alloc] init];
    PEXGuiDialogProgressCanceller * const canceller = [[PEXGuiDialogProgressCanceller alloc] initWithController:progress];
    canceller.howToDismiss = ^{dispatch_async(dispatch_get_main_queue(), ^(void)
    {
        [self.topController dismissViewControllerAnimated:true completion:nil];
    });
    };

    PEXGuiController * const vc =
            [[PEXGuiDialogUnaryController alloc] initWithVisitor:canceller];

    PEXGuiWindowController * const taskWindowController = [[PEXGuiWindowController alloc] initWithViewController:vc];

    PEXLoginTask * const task = [[PEXLoginTask alloc] initWithCredentials:self.credentials
                                                               controller:taskWindowController];

    [progress setTheTask:task];
    [canceller setTheTask:task];

    [task addListener:self];
    self.topController = taskWindowController;

    [super show];

    [taskWindowController prepareOnScreen:self.parentController];
    [taskWindowController show:self.parentController];
}

-(void) taskEnded:(const PEXTaskEvent *const)event
{
    PEXLoginTaskResult * const result = [((PEXLoginTaskEventEnd *) event) getResult];
    dispatch_async(dispatch_get_main_queue(), ^(void)
                {
                    [self dismissWithCompletion:^{[self loginFinished: result];}];
                });
}

- (void) taskStarted: (const PEXTaskEvent * const) event {}
- (void) taskCancelStarted: (const PEXTaskEvent * const) event {}
- (void) taskCancelEnded: (const PEXTaskEvent * const) event {}
- (void) taskProgressed: (const PEXTaskEvent * const) event {}
- (void) taskCancelProgressed: (const PEXTaskEvent * const) event {}

- (void) loginFinished: (PEXLoginTaskResult * const)loginResult
{
    if (loginResult.resultDescription != PEX_LOGIN_TASK_RESULT_LOGGED_IN)
    {
        [self loginFailed:loginResult];
    }
    else
    {
        [PEXLoginExecutor loginAftermath:self.credentials.username];
        [PEXLoginExecutor showLoggedGui:true];

#ifdef PEX_BUILD_DEBUG
        //[self createFiles];
#endif
    }
}

- (void) createFiles
{
    for (int i = 0; i < 10; ++i)
    {
        //make a file name to write the data to using the documents directory:
        NSString *fileName = [[PEXGuiFileUtils getFileTransferPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"textfile%d.txt", i]];

        //create content - four lines of text
        NSString *content = @"Debug1\nDebug2\nDebug3\nDebug4\nDebug5";

        //save content to the documents directory
        [content writeToFile:fileName
                  atomically:NO
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
}

- (NSString *) stringForReason: (const PEXLoginTaskResult *) res defaultText: (NSString *) defaultText {
    if ([PEXUtils isEmpty: res.serverFailDesc] && [PEXUtils isEmpty: res.serverFailTitle]){
        return defaultText;
    }

    if (![PEXUtils isEmpty: res.serverFailTitle] && ![PEXUtils isEmpty: res.serverFailDesc]){
        return [NSString stringWithFormat:@"%@\n\n%@", res.serverFailTitle, res.serverFailDesc];
    }

    if (![PEXUtils isEmpty: res.serverFailDesc ]){
        return res.serverFailDesc;
    }

    if (![PEXUtils isEmpty: res.serverFailTitle]){
        return res.serverFailTitle;
    }

    return defaultText;
}

- (void) updatePrimary {
    [PEXVersionChecker openUpdateWindow];
}

- (void) updateSecondary {
    [self.updateController dismissViewControllerAnimated:YES completion:nil];
}

- (void) loginFailed: (const PEXLoginTaskResult *) loginResult
{
    NSString * text;

    // Old version with possible update - different handling.
    if (loginResult.resultDescription == PEX_LOGIN_TASK_RESULT_OLD_VERSION){
        WEAKSELF;
        text = [self stringForReason:loginResult defaultText:PEXStr(@"msg_old_version")];
        self.updateController = [PEXGuiFactory showBinaryDialog:self.parentController
                                                       withText:text
                                              primaryActionName:PEXStrU(@"B_update")
                                            secondaryActionName:nil
                                                  primaryAction:^(PEXGuiController *controller) {
                                                      [weakSelf updatePrimary];
                                                  }
                                                secondaryAction:^(PEXGuiController *controller) {
                                                    [weakSelf updateSecondary];
                                                }];
        return;
    }

    switch (loginResult.resultDescription)
    {
        case PEX_LOGIN_TASK_RESULT_INCORRECT_CREDENTIALS:
            text = PEXStr(@"msg_incorrect_credentials");
            break;

        case PEX_LOGIN_TASK_RESULT_NO_NETWORK:
            text = PEXStr(@"msg_no_network");
            break;

        case PEX_LOGIN_TASK_RESULT_CONNECTION_PROBLEM:
            text = PEXStr(@"msg_connection_problem");
            break;

        case PEX_LOGIN_TASK_RESULT_SERVERSIDE_PROBLEM:
            text = [self stringForReason:loginResult defaultText:PEXStr(@"msg_serverside_problem")];
            break;

        case PEX_LOGIN_TASK_DATABASE_ERROR:
            text = PEXStr(@"msg_database_error");
            break;

        case PEX_LOGIN_TASK_RESULT_CLOCK_PROBLEM:
            // TODO: format this properly.
            text = [NSString stringWithFormat:@"%@\n\n%@: %@\n%@: %@",
                            PEXStr(@"msg_clock_problem"),
                            PEXStr(@"L_server"), [PEXDateUtils dateToFullDateString:loginResult.serverTime],
                            PEXStr(@"L_local"), [PEXDateUtils dateToFullDateString:[NSDate date]]];

            break;

        case PEX_LOGIN_TASK_RESULT_ACCOUNT_DISABLED:
            text = [self stringForReason:loginResult defaultText:PEXStr(@"msg_account_disabled_problem")];
            break;

        case PEX_LOGIN_TASK_RESULT_INCOMPATIBLE_VERSION:
            text = [self stringForReason:loginResult defaultText:PEXStr(@"msg_incompatible_version")];
            break;

        case PEX_LOGIN_TASK_RESULT_TRIAL_EXPIRED:
            text = PEXStr(@"msg_trial_expired_problem");
            break;

        case PEX_LOGIN_TASK_RESULT_ILLEGAL_LOGIN_NAME:
            text = PEXStr(@"msg_incorrect_credentials");
            break;

        case PEX_LOGIN_TASK_RESULT_TLS_CACHE_BUG:
            text = [NSString stringWithFormat:@"%@\n\n%@",
            PEXStr(@"msg_login_tls_bug"), PEXStr(@"txt_restart_app_detail_description")];
            break;

        case PEX_LOGIN_TASK_RESULT_GENERIC_SERVER_FAIL:
        case PEX_LOGIN_TASK_RESULT_UNSPECIFIED_SERVER_FAIL:
            text = [self stringForReason:loginResult defaultText:PEXStr(@"msg_serverside_problem")];
            break;

        case PEX_LOGIN_TASK_CANCELLED:
            return;

        default:
            return;
    }

    [PEXGuiFactory showErrorTextBox:self.parentController withText:text];
}

// Here are initialized the most important thing for notifications
+ (void) loginAftermath: (NSString * const) username
{
    PEXAppState * const appState = [PEXAppState instance];
    [appState setLogged: true];

    // because of relog, e.g. after password change
    // DEPRECATED See IPH-294
    //if (![[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_KEY
    //                                           defaultValue:PEX_PREF_USE_KEYCHAIN_FOR_PASSWORD_DEFAULT])
    //{
    //    [PEXLoginHelper resetKeychain];
    //}

    // USER Update
    [PEXUserUpdater updateIfNeeded];
    [[PEXANFC instance] register];

    if (!appState.chatAccountingManager)
        appState.chatAccountingManager = [[PEXChatAccountingManager alloc] init];

    PEXChatsManager * const chatsManager = [[PEXChatsManager alloc] init];
    [chatsManager initContent];
    appState.chatsManager = chatsManager;

    PEXCallsManager * const callsManager = [[PEXCallsManager alloc] init];
    [callsManager initContent];
    appState.callsManager = callsManager;

    PEXContactNotificationManager * const contactNotificationManager =
            [[PEXContactNotificationManager alloc] init];
    [contactNotificationManager initContent];
    appState.contactNotificationManager = contactNotificationManager;

    // TODO permission notifications
    //[appState.licenceManager notifyIfLicenceRequiresAttention];

    // Loading server time after auto-login
    if (!appState.referenceTimeManager)
        appState.referenceTimeManager = [[PEXReferenceTimeManager alloc] init];

    [appState.referenceTimeManager addListener:[[PEXService instance] licenceManager]];

    [appState.referenceTimeManager startCheckForTimeIfNeeded: ^{
        [[[PEXService instance] licenceManager] setExpirationCheckTaskIfNeeded];
    }];

    [PEXLogsUtils removeAllTooOldLogsAsyncOlderThanDay];
    [PEXReport logScreenName:PEX_EVENT_SCREEN_CONTACTS];
}

// called only on active state
// processes that should be visible only on active state
+ (void)showLoggedGui: (const bool) animated
{
    PEXAppState * const appState = [PEXAppState instance];

    [[[PEXService instance] licenceManager] addListenerAndSet:appState.chatAccountingManager
                                     forPrefix:PEX_PERMISSION_MESSAGES_PREFIX];

    // TODO IPH-183 Inform user of deleted messages during his absence
    [[PEXMessageArchiver instance] setTimerInSeconds:
            [[PEXUserAppPreferences instance] getNumberPrefForKey:PEX_PREF_MESSAGE_ARCHIVE_TIME_KEY
                                                     defaultValue:PEX_PREF_MESSAGE_ARCHIVE_TIME_DEFAULT]];

    [[PEXGuiPinLockManager instance] resetTrigger];
    [appState resetPinLockAttempts];

    // Main screens
    PEXGuiMainTabController * const tabsController = [self initMainScreensWithChatsManager:appState.chatsManager
                                                                              callsManager:appState.callsManager];

    NSString * const username = [[PEXAppState instance] getPrivateData].username;

    // TODO dirty hack for Licence notification
    // TODO permission notifications
    /*
    const bool licencNotificationSeen = [[PEXUserAppPreferences instance]
            getBoolPrefForKey:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY
                 defaultValue:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_DEFAULT];
                 */

    UIViewController * const landingController =
            // TODO this is a bad approach
            //[tabsController showInLabel:self.parentController
            [tabsController showInLabel:[PEXGuiLoginController instance]
                                  title: [username substringToIndex:[username rangeOfString:@"@"].location]
                               animated:animated];

    [PEXGuiLoginController instance].landingController = landingController;

    [[PEXGuiNoticeManager instance] reshowNoticeIfNeeded];

    // TODO dirty hack for Licence notification
    // TODO permission notifications
    /*
    [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_LICENCE_UPDATE_NOTIFICATION_SEEN_KEY
                                                  value:licencNotificationSeen];
    [appState.licenceManager notifyIfLicenceRequiresAttention];
     */


    if (PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_DEFAULT
            && ![[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_KEY
                                               defaultValue:PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_DEFAULT])
    {
        [PEXGuiFactory showTextBox:landingController withText:PEXStr(@"txt_google_analytics_are_on") completion:
                ^{
                    [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_GOOGLE_ANALYTICS_INFO_SHOWN_KEY
                                                                  value:true];
                }];
    }

    if ([[PEXUserAppPreferences instance] getBoolPrefForKey:PEX_PREF_FIRST_TIME_KEY
                                                defaultValue:PEX_PREF_FIRST_TIME_DEFAULT])
    {
        [PEXGuiFactory showTextBox:landingController withText:PEXStr(@"txt_inapp_intro") completion:
                ^{
                    [[PEXUserAppPreferences instance] setBoolPrefForKey:PEX_PREF_FIRST_TIME_KEY
                                                                  value:false];
                }];
    }

    appState.appLoggedGuiWasShown = true;
}

+ (PEXGuiMainTabController *) initMainScreensWithChatsManager: (PEXChatsManager * const) chatsManager
                                                 callsManager: (PEXCallsManager * const) callsManager
{
    // MESSY CODE APPROACHING

    NSMutableArray * const tabsArgs = [[NSMutableArray alloc] init];

    // contacts
    PEXGuiTabContainer * contacts = [[PEXGuiTabContainer alloc] init];
    PEXGuiTabView * contactsView = [[PEXGuiContactsNotifiedTabView  alloc]
            initWithImage:[[PEXGuiImageView alloc]
                    initWithImage:PEXImg(@"contact_book")]
                labelText:nil/*PEXStrU(@"menu_contacts")*/
           highlightImage:[[PEXGuiImageView alloc]
                   initWithImage:PEXImg(@"contact_book_highlight")]];
    contacts.tabView = contactsView;
    contacts.tabController = [[PEXGuiContactControllerList alloc] init];
    [tabsArgs addObject:contacts];

    // conversations
    PEXGuiTabContainer * conversations = [[PEXGuiTabContainer alloc] init];
    PEXGuiNotifiedTabView * conversationsView = [[PEXGuiMessageNotifiedTabView alloc]
            initWithImage:[[PEXGuiImageView alloc]
                    initWithImage:PEXImg(@"chat")]
                labelText:nil
           highlightImage:[[PEXGuiImageView alloc]
                   initWithImage:PEXImg(@"chat_highlight")]];
    /*PEXStrU(@"menu_conversations")*/

    conversations.tabView = conversationsView;
    PEXGuiChatsController * chatsController = [[PEXGuiChatsController alloc] init];
    chatsController.manager = chatsManager;
    conversations.tabController = chatsController;
    [tabsArgs addObject:conversations];

    // calls

    PEXGuiTabContainer * calls = [[PEXGuiTabContainer alloc] init];
    PEXGuiNotifiedTabView * callsView = [[PEXGuiCallLogNotifiedTabView alloc]
            initWithImage:[[PEXGuiImageView alloc]
                    initWithImage:PEXImg(@"phone")]
                labelText:nil
           highlightImage:[[PEXGuiImageView alloc]
                   initWithImage:PEXImg(@"phone_highlight")]];
    /*PEXStrU(@"L_calls")*/
    calls.tabView = callsView;
    PEXGuiCallsController * callsController = [[PEXGuiCallsController alloc] init];
    callsController.manager = callsManager;
    calls.tabController = callsController;
    [tabsArgs addObject:calls];

    // profile
    PEXGuiTabContainer * profile = [[PEXGuiTabContainer alloc] init];
    PEXGuiProfileUpdateNotifiedTabView * profileView = [[PEXGuiProfileUpdateNotifiedTabView alloc]
            initWithImage:[[PEXGuiImageView alloc]
                    initWithImage:PEXImg(@"contact")]
                labelText:nil
           highlightImage:[[PEXGuiImageView alloc]
                   initWithImage:PEXImg(@"contact_highlight")]];

    profile.tabView = profileView;
    profile.tabController = [[PEXGuiProfileController alloc] init];
    [tabsArgs addObject:profile];

    // debug tuning
    NSInteger tuningAllowed = [[PEXUserAppPreferences instance] getIntPrefForKey:PEX_PREF_DEBUG_VIEW
                                                                    defaultValue:PEX_PREF_DEBUG_VIEW_DEFAULT];
    PEXGuiTuningController * const tuningController = [[PEXGuiTuningController alloc] init];
    if ([PEXUtils isDebug] || tuningAllowed)
    {
        PEXGuiTabContainer * tuning = [[PEXGuiTabContainer alloc] init];
        PEXGuiTabView * tuningView = [[PEXGuiTabView alloc]
                initWithImage:[[PEXGuiImageView alloc]
                        initWithImage:PEXImg(@"devel")]
                    labelText:nil
               highlightImage:[[PEXGuiImageView alloc]
                       initWithImage:PEXImg(@"devel_highlight")]];

        tuning.tabView = tuningView;
        tuning.tabController = tuningController;
        [tabsArgs addObject:tuning];
    }

    // others

    PEXGuiMainTabController * const result = [[PEXGuiMainTabController alloc] initWithTabViews:tabsArgs];

    result.tabDidReveal = ^(const NSUInteger index) {
        // Google analytics tab switching monitoring.
        switch(index){
            default:
                break;
            case 0:
                [PEXReport logScreenName:PEX_EVENT_SCREEN_CONTACTS];
                break;
            case 1:
                [PEXReport logScreenName:PEX_EVENT_SCREEN_CHATS];
                break;
            case 2:
                [PEXReport logScreenName:PEX_EVENT_SCREEN_CALLLOG];
                break;
            case 3:
                [PEXReport logScreenName:PEX_EVENT_SCREEN_PROFILE];
                break;
        }
    };

    __weak PEXGuiTuningController * weakTuningController = tuningController;
    result.tabSelected = ^(const NSUInteger previousIndex, const NSUInteger currentIndex) {

        switch (previousIndex)
        {
            case 3:
                if (currentIndex != 3)
                    [[PEXGNFC instance] unsetLicenceUpdateNorificationAsync];

                break;

            case 2:
                if (currentIndex != 2)
                    [[PEXGNFC instance] seeAllCallLogNotifications];

                break;
        }

        // Google analytics tab switching monitoring.
        switch(currentIndex){
            default:
                break;
            case 0:
                [PEXReport logUsrButton:PEX_EVENT_BTN_TAB_CONTACTS];
                [PEXReport logScreenName:PEX_EVENT_SCREEN_CONTACTS];
                break;
            case 1:
                [PEXReport logUsrButton:PEX_EVENT_BTN_TAB_CHATS];
                [PEXReport logScreenName:PEX_EVENT_SCREEN_CHATS];
                break;
            case 2:
                [PEXReport logUsrButton:PEX_EVENT_BTN_TAB_CALLLOG];
                [PEXReport logScreenName:PEX_EVENT_SCREEN_CALLLOG];
                break;
            case 3:
                [PEXReport logUsrButton:PEX_EVENT_BTN_TAB_PROFILE];
                [PEXReport logScreenName:PEX_EVENT_SCREEN_PROFILE];
                break;
            case 4:
                if (weakTuningController)
                {
                    [weakTuningController fillRegFields];
                    [weakTuningController fillStatusText];
                }
                break;
        }
    };

    // DEMO
    //[PEXContactNotificationManager addMockContactNotificationAsync];

    return result;
}

@end
