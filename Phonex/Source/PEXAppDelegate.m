//
//  PEXAppDelegate.m
//  Phonex
//
//  Created by Matej Oravec on 25/07/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "PEXAppDelegate.h"
#import "PEXGuiLoginController.h"
#import "PEXDatabase.h"
#import "PEXDDLogFormatter.h"
#import "PEXService.h"

#import "PEXGuiPinLockManager.h"

#import "PEXGuiShieldManager.h"
#import "PEXGuiCallManager.h"
#import "PEXCredentials.h"

#import "PEXGuiKeyboardHolder.h"
#import "PEXGuiCallManager.h"

#import "PEXTimeUtils.h"
#import "PEXDDLogToFile.h"
#import "PEXGuiNotificationCenter.h"

#import "PEXGuiExternUrlManager.h"
#import "PEXGuiFactory.h"
#import "PEXFileData.h"
#import "PEXFilePickManager.h"
#import "PEXGuiFileUtils.h"
#import "PEXGlobalUpdater.h"
#import "Flurry.h"
#import "PEXFlurry.h"
#import "PEXUtils.h"
#import "PEXLoginHelper.h"
#import "PEXCredentials.h"
#import "PEXSystemUtils.h"
#import "PEXLoginTask.h"
#import "PEXTask_Protected.h"
#import "PEXMessageArchiver.h"
#import "PEXAutoLoginManager.h"
#import "PEXSOAPManager.h"
#import "PEXLoginExecutor.h"
#import "PEXPushCenter.h"
#import "PEXPushManager.h"
#import "PEXReport.h"
#import "PEXGAILogger.h"
#import "PEXTouchId.h"
#import "PEXLicenceManager.h"
#import "PEXFileRestrictorManager.h"
#import "PEXPaymentManager.h"

#if PEX_GAI_TRACKING
#  import <Google/Analytics.h>
#endif

typedef struct timespec timespec;
@interface PEXAppDelegate ()
{
@private
    uint64_t _wentInBackgroundNanoseconds;
    bool _showingStuffAfterAutoLogin;
    bool _allowToSetAppActive;
}

@end

@implementation PEXAppDelegate

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)())completionHandler
{
    DDLogInfo(@"handleEventsForBackgroundURLSession: identifier: %@", identifier);
    /*
     Store the completion handler. The completion handler is invoked by the view controller's checkForAllDownloadsHavingCompleted method (if all the download tasks have been completed).
     */
}

-(void) initFlurry {
    [[PEXReport sharedInstance] flurryInit];
}

-(void) initGoogleAnalytics {
    [[PEXReport sharedInstance] googleAnalyticsInit];
}

- (void) initLogger
{
    [[DDTTYLogger sharedInstance] setLogFormatter:[PEXDDLogFormatter sharedInstance]];
    [[DDASLLogger sharedInstance] setLogFormatter:[PEXDDLogFormatter sharedInstance]];
    [DDLog removeAllLoggers];
//    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    DDFileLogger* fileLogger = [PEXDDLogToFile instance];
    [fileLogger setLogFormatter: [PEXDDLogFormatter sharedInstance]];
    [DDLog addLogger:fileLogger];
    [PEXBase loadLogLevelFromPrefs];
    [PEXBase setLogSyncFromPrefs];
}

- (void) notifyLaunched: (NSDictionary * const)launchOptions
{
    // Notify user app has been started - monitoring of iOS app restart.
    UILocalNotification * const localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"App started";
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    AudioServicesPlaySystemSound(1007);
    DDLogVerbose(@"App has been started, options: %@", launchOptions);
}

- (void) registerForNotifications
{
    // Fix for the badging on iOS 8+
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        UIUserNotificationType types = UIUserNotificationTypeSound | UIUserNotificationTypeBadge | UIUserNotificationTypeAlert;
        UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
}

- (PEXGuiLoginController *) prepareLoginScreenWithPostShield: (const bool) withShield
{
    // Window creation. If app has crashed, it stops somewhere here.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    PEXGuiLoginController * loginControler = [PEXGuiLoginController instance];

    if (withShield)
        [loginControler setPostLaunchShield];

    self.window.rootViewController = loginControler;
    [loginControler prepareOnScreen: nil];

    return loginControler;
}

- (void)showAfterLogin
{
    [PEXGVU executeWithoutAnimations:^{

        [self prepareLoginScreenWithPostShield:true];

        [self.window makeKeyAndVisible];

        [PEXLoginExecutor loginAftermath:[[PEXAppState instance] getPrivateData].username];
    }];
}

- (PEXGuiLoginController *)showBeforeLogin
{
    PEXGuiLoginController * const result = [self prepareLoginScreenWithPostShield:false];

    [self.window makeKeyAndVisible];
    _allowToSetAppActive = true;

    return result;
}

+ (bool) startAutoLoginOnSuccess: (void (^)(void))onSuccess
                       onFailureWithCredentials: (void (^)(const PEXCredentials *))onFailed
{
    PEXAutoLoginManager * autoLogin = [PEXAutoLoginManager newInstanceNotThreadSafe];
    const BOOL credentialAreInKeychain = [autoLogin fastInit];

    if (!credentialAreInKeychain) {
        return false;
    }

    // Start login process.
    // This call waits for complete service initialization because if app is running in the background we have to
    // perform all essential tasks on the main thread in didFinishLaunching.
    autoLogin.waitOnCompleteSvcInit = YES;

    DDLogVerbose(@"<autologin>");
    [PEXReport logEvent:PEX_EVENT_AUTOLOGIN_STARTED];

    const BOOL autoLoginPrepaired = [autoLogin prepareAutoLogin];
    if (!autoLoginPrepaired) {
        [PEXReport logEvent:PEX_EVENT_AUTOLOGIN_FAILED];

        if ([autoLogin shouldTryNormalLogin]){
            // IPH-326 notify user app could not login automatically, manual login is required. Use autoLogin.creds
            if (onFailed)
            {
                onFailed(autoLogin.creds);
                [autoLogin quit];
                return true;
            }
        }

        [autoLogin quit];
        return false;
    }

    if ([autoLogin doAutoLogin] != PEX_AUTOLOGIN_SUCC) {

        [PEXReport logEvent:PEX_EVENT_AUTOLOGIN_FAILED];

        if ([autoLogin shouldTryNormalLogin]) {
            // IPH-326 notify user app could not login automatically, manual login is required. Use autoLogin.creds
            if (onFailed) {
                onFailed(autoLogin.creds);
                [autoLogin quit];
                return true;
            }
        }

        [autoLogin quit];
        return false;
    }

    [PEXService instance].lastLoginUserName = autoLogin.creds.username;
    [PEXReport logEvent:PEX_EVENT_AUTOLOGIN_FINISHED];

    if (onSuccess)
    {
        onSuccess();
        return true;
    }

    DDLogVerbose(@"</autologin>");

    return false;
}

- (void) autologinFailedWithCredentials: (const PEXCredentials * const) credentials
{
    if (![[PEXAppState instance] isAppActive])
        [[PEXAppNotificationCenter instance] showAttentionNotification];

    PEXGuiLoginController * const loginController = [self showBeforeLogin];

    [loginController autoLoginFailedWithCredentials:credentials];
}

- (void) fireUpTheShow
{
    const bool appLaunchedBefore = [[PEXAppPreferences instance] getBoolPrefForKey:PEX_PREF_APP_WAS_LAUNCHED_BEFORE_KEY
                                                                      defaultValue:PEX_PREF_APP_WAS_LAUNCHED_BEFORE_DEFAULT];

    _allowToSetAppActive = false;
    if (!appLaunchedBefore)
    {
        [PEXLoginHelper resetKeychain];
        [[PEXAppPreferences instance] setBoolPrefForKey:PEX_PREF_APP_WAS_LAUNCHED_BEFORE_KEY
                                                  value:true];
    }

    const bool autologinContinuesSomehow = [PEXAppDelegate startAutoLoginOnSuccess:^{

        _showingStuffAfterAutoLogin = true;
        [self showAfterLogin];

    } onFailureWithCredentials:^(const PEXCredentials * const credentials){

        [self autologinFailedWithCredentials:credentials];

    }];

    // fallback - show login screen
    if (!autologinContinuesSomehow) {
        [self showBeforeLogin];
    }

    DDLogInfo(@"Application started");
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initLogger];
    [self initFlurry];
    [self initGoogleAnalytics];
    [PEXPaymentManager registerForDelayed];

    [PEXGlobalUpdater updateIfNeeded];
    [self registerForNotifications];
    [[PEXAppState instance] setLogged: false];
    [[PEXGuiPinLockManager instance] setBeyondPinLock: true];

    // Cleanup potentially forgotten notifications.
    [[PEXANFC instance] reset];

#ifdef PEX_BUILD_DEBUG
    [self notifyLaunched:launchOptions];
#endif

    [self fireUpTheShow];

    return YES;
}

- (void) activateUi
{
    const uint64_t currentTime = PEXGetPIDTimeInNanoseconds();

    PEXAppState * const appState = [PEXAppState instance];
    [appState setIsAppActive: true];

    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);

    if (!appState.appLoggedGuiWasShown && appState.logged)
    {
        [PEXLoginExecutor showLoggedGui:false];
    }

    if ([PEXGuiLoginController instance].landingController)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PEXMessageArchiver instance] resume];
        });

        // touch ID stuff
        // We need to check touchID settings manually and adapt Preferences controller and
        // whether we use the touchID for unlocking the app
        // TODO This should be also done at login
        [PEXTouchId checkTouchIdDeviceStatusAndAdjustSetting];

    }

    // shield and pinlock must be shown/hidden immediatelly without animations
    [PEXGVU executeWithoutAnimations:^{
        [[PEXGuiShieldManager instance] bringToFront];

        // nanoseconds to seconds 1000000000LLU

        uint64_t secondsForPinlock = (currentTime - _wentInBackgroundNanoseconds) / 1000000000LLU;
        if (_showingStuffAfterAutoLogin)
        {
            secondsForPinlock = ULLONG_MAX;
            _showingStuffAfterAutoLogin = false;
        }

        [[PEXGuiPinLockManager instance] showPinLockOnBecomingActive: secondsForPinlock
                                                          forLanding:[PEXGuiLoginController instance].landingController
                                                           forceShow:false];

        [[PEXGuiCallManager instance] bringTheCallToFront];
        [[PEXGuiShieldManager instance] hideShield];
    }];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);

    [self activateUi];

    [[PEXService instance] onApplicationWillEnterForeground: application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    if (_showingStuffAfterAutoLogin)
    {
        [self activateUi];
    }

    // This code path is invoked when auto-login fails to start.
    // Needed for IPH-361, when user logs in via creating a new account or manually by entering credentials
    // he is not able to mark incoming messages as read. App needs to be set to active.
    if (_allowToSetAppActive){
        PEXAppState * const appState = [PEXAppState instance];
        [appState setIsAppActive: true];
    }

    [[PEXService instance] onApplicationDidBecomeActive: application];
    [[PEXANFC instance] hideAppStartedInBackgroundNotification];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);

    [[PEXService instance] onApplicationWillResignActive: application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);

    [[PEXAppState instance] setIsAppActive: false];
    [[PEXAppNotificationCenter instance] hideAttentionNotification];

    if (![PEXGuiLoginController instance].landingController)
    {
        [[PEXANFC instance] showAppStartedInBackgroundNotification];
    }

    [[PEXGuiKeyboardHolder instance] stopEditing];
    [[PEXGuiLoginController instance] cleanTraces];

    // shield and pinlock must be shown/hidden immediatelly without animations
    [PEXGVU executeWithoutAnimations:^{
        [[PEXGuiShieldManager instance] showShield];
        [[PEXGuiPinLockManager instance] hidePinLockForGoingToBackground];
    }];

    if ([PEXGuiLoginController instance].landingController)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PEXMessageArchiver instance] pause];
        });
    }

    _wentInBackgroundNanoseconds = PEXGetPIDTimeInNanoseconds();

    [[PEXService instance] onApplicationDidEnterBackground: application];
    [DDLog flushLog];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);

    [[PEXANFC instance] reset];

    [[PEXService instance] onApplicationWillTerminate: application];
    [DDLog flushLog];

#ifdef PEX_BUILD_DEBUG
    // Notify user app has been terminated - monitoring of sudden termination.
    // TODO: notify user app has been terminated. User should start the app if wants to receive calls & messages.
    UILocalNotification * const localNotification = [[UILocalNotification alloc] init];
    localNotification.alertBody = @"App termination";
    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    AudioServicesPlaySystemSound(1010);
    [NSThread sleepForTimeInterval:1.0];
#endif
}

// Executed before didBecomeActive:
- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    bool result = false;
    NSString * errorText = nil;

    // Analyze scheme of the link being opened.
    // It might be phonex:// scheme.
    if ([@"phonex" isEqualToString:url.scheme]){
        DDLogVerbose(@"url: %@", url);

        // Test for host.
        NSArray * pathComponents = url.pathComponents;
        if ((![@"www.phone-x.net" isEqualToString:url.host] && ![@"phone-x.net" isEqualToString:url.host])
                || pathComponents == nil
                || [pathComponents count] < 2
                || ![@"/" isEqualToString:pathComponents[0]])
        {
            errorText = PEXStr(@"txt_cannot_open_link");
            result = NO;

        // Known actions follow.
        } else if ([@"recoverycode" isEqualToString:pathComponents[1]]){
            result = [self processRecoveryCodeUrl:url errorText:&errorText];

        } else {
            errorText = PEXStr(@"txt_cannot_open_link_unknown");
            result = NO;
        }

        if (errorText != nil){
            [PEXGuiFactory showErrorTextBox:[PEXGuiLoginController instance] withText:errorText];
        }

        return result;
    }

    // File transfer opening URL logic.
    // logged in?
    UIViewController * displayController = [PEXGuiLoginController instance].landingController;
    if (![PEXGuiLoginController instance].landingController)
    {
        errorText = PEXStr(@"txt_login_to_open_files");
        displayController = [PEXGuiLoginController instance];
    }
    // is it a file?
    else if (url.isFileURL)
    {
        PEXFileData * const fileData = [PEXFileData fileDataFromUrl:url];

        if (fileData)
        {
            result = [self processFileForSendingForFile:fileData errorText:&errorText];
        }
        else
        {
            errorText = PEXStr(@"txt_error_during_processing");
        }
    }
    else
    {
        errorText = PEXStr(@"txt_cannot_open_such_resource");
    }

    if (errorText) {
        [PEXGuiFactory showErrorTextBox:displayController withText:errorText];
    }

    return result;
}

- (bool) processRecoveryCodeUrl: (NSURL *)url errorText: (NSString ** const) errorText{
    NSArray * pathComponents = url.pathComponents;
    if (url == nil || pathComponents == nil || [pathComponents count] < 3){
        if (errorText){
            *errorText = PEXStr(@"txt_open_recovery_link_malformed");
        }

        return NO;
    }

    // Some basic checks on the recovery code presence.
    NSString * recoveryCode = pathComponents[2];
    if (recoveryCode == nil
            || [PEXStringUtils isEmpty:recoveryCode])
    {
        if (errorText){
            *errorText = PEXStr(@"txt_open_recovery_link_malformed");
        }

        return NO;
    }

    // Only of not logged in.
    if ([PEXGuiLoginController instance].landingController)
    {
        if (errorText){
            *errorText = PEXStr(@"txt_open_recovery_link_already_logged_in");
        }

        return NO;
    }

    // Pass to login controller.
    [[PEXGuiLoginController instance] recoveryCodePassed:recoveryCode];

    return YES;
}

- (bool) processFileForSendingForFile: (PEXFileData * const) fileData errorText: (NSString ** const) errorText
{
    bool result = false;

    PEXFileRestrictorFactory * const factory = [[[PEXService instance] licenceManager] fileRestrictorFactory];
    PEXFileRestrictorManager * const restrictionManager = [factory createManagerInstance];

    [restrictionManager setFiles:@[fileData]];
    const PEXSelectionDescriptionStatus status = [restrictionManager checkFileRestrictionStatus];

    // TODO better error messages
    // TODO use getRestrictorsDescriptions
    if (status != PEX_SELECTION_DESC_STATUS_OK)
    {
        switch (status) {
            case PEX_SELECTION_DESC_STATUS_TOO_MANY_FILES:
                *errorText = PEXStr(@"txt_cannot_send_any_more_files");
                break;

            case PEX_SELECTION_DESC_STATUS_TOO_LARGE:
                *errorText = PEXStr(@"txt_cannot_send_more_than_max");
                break;

            case PEX_SELECTION_DESC_STATUS_ERROR:
                *errorText = PEXStr(@"txt_error");
                break;
            case PEX_SELECTION_DESC_STATUS_OK:break;
            case PEX_SELECTION_DESC_STATUS_TOO_FEW_FILES:break;
            case PEX_SELECTION_DESC_STATUS_TOO_SMALL:break;
        }
    }
    else
    {
        result = [[PEXGuiExternUrlManager instance] sendExternalData:fileData];
        if (!result)
            *errorText = PEXStr(@"txt_error_during_processing");
    }

    [factory destroyManagerInstance:restrictionManager];

    return result;
}

- (void)applicationSignificantTimeChange:(UIApplication *)application {
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[PEXService instance] onLowMemoryWarning: application];
    [DDLog flushLog];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    DDLogInfo(@"%@: %@, token=%@", THIS_FILE, THIS_METHOD, deviceToken);
    PEXPushManager * pmgr = [PEXService instance].pushManager;
    [pmgr onDeviceTokenUpdated:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    DDLogInfo(@"%@: %@, error=%@", THIS_FILE, THIS_METHOD, error);
    PEXPushManager * pmgr = [PEXService instance].pushManager;
    [pmgr onDeviceTokenFail:error];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    DDLogInfo(@"%@: %@, info=%@", THIS_FILE, THIS_METHOD, userInfo);
    PEXPushManager * pmgr = [PEXService instance].pushManager;
    [pmgr onRemotePushReceived:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application {
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
    [DDLog flushLog];
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
    DDLogInfo(@"%@: %@", THIS_FILE, THIS_METHOD);
}


@end
