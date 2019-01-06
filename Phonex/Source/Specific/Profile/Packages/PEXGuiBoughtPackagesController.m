//
// Created by Matej Oravec on 20/10/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiBoughtPackagesController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiClickableScrollView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiButtonMain.h"
#import "PEXGuiPoint.h"
#import "PEXLicenceManager.h"
#import "PEXPermissionsUtils.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "PEXPackageHumanDescription.h"
#import "PEXGuiClassicLabel.h"
#import "PEXDbAccountingPermission.h"
#import "PEXGuiTimeUtils.h"
#import "PEXGuiCallController.h"
#import "PEXPaymentManager.h"
#import "PEXService.h"
#import "PEXGuiTextView_Protected.h"
#import "PEXLicenseLoader.h"
#import "PEXUtils.h"
#import "UITextView+PEXPaddings.h"

@interface PEXGuiBoughtPackagesController ()

@property (nonatomic) NSLock * lock;
@property (nonatomic) dispatch_queue_t queue;

@property (nonatomic) PEXGuiClickableScrollView * V_scroller;

@property (nonatomic) PEXGuiReadOnlyTextView *L_subscriptionsSummary;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_subscriptions;
@property (nonatomic) PEXGuiButtonMain * B_manageSubscriptions;

@property (nonatomic) PEXGuiPoint * line;

@property (nonatomic) PEXGuiReadOnlyTextView *L_consumeableSummary;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_consumeables;

@property (nonatomic) PEXLicenseLoader * licLoader;
@property (nonatomic) NSDictionary * licenses;

@property (nonatomic) NSDictionary * consumedSummary;
@property (nonatomic) NSDictionary * subscriptionsSummary;

@end

@implementation PEXGuiBoughtPackagesController {

}

- (void)initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"GetPremium";


    self.V_scroller = [[PEXGuiClickableScrollView alloc] init];
    [self.mainView addSubview:self.V_scroller];

    self.L_subscriptionsSummary = [[PEXGuiReadOnlyTextView alloc] init];;
    [self.V_scroller addSubview:self.L_subscriptionsSummary];

    self.TV_subscriptions = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_scroller addSubview:self.TV_subscriptions];

    self.B_manageSubscriptions = [[PEXGuiButtonMain alloc] init];
    [self.V_scroller addSubview:self.B_manageSubscriptions];

    self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
    [self.V_scroller addSubview:self.line];

    self.L_consumeableSummary = [[PEXGuiReadOnlyTextView alloc] init];;
    [self.V_scroller addSubview:self.L_consumeableSummary];

    self.TV_consumeables = [[PEXGuiReadOnlyTextView alloc] init];
    [self.V_scroller addSubview:self.TV_consumeables];
}

- (void)initContent
{
    [super initContent];

    PEXGuiDetailsTextBuilder * const builder3 = [[PEXGuiDetailsTextBuilder alloc] init];
    [builder3 appendLabel:PEXStrU(@"L_subscriptions") first:YES fontSize:@(PEXVal(@"dim_size_medium")) fontColor:NULL];
    [builder3 appendValue:PEXStrU(@"L_subscriptions_desc")];
    [self.L_subscriptionsSummary setAttributedText:[builder3 result]];

    [self.B_manageSubscriptions setTitle:PEXStrU(@"L_manage_subscriptions") forState:UIControlStateNormal];

    PEXGuiDetailsTextBuilder * const builder4 = [[PEXGuiDetailsTextBuilder alloc] init];
    [builder4 appendLabel:PEXStrU(@"L_consumeables") first:YES fontSize:@(PEXVal(@"dim_size_medium")) fontColor:NULL];
    [builder4 appendValue:PEXStrU(@"L_consumeables_desc")];
    [self.L_consumeableSummary setAttributedText:[builder4 result]];
}

- (void)initBehavior
{
    [super initBehavior];

    [self.B_manageSubscriptions addTarget:self action:@selector(manageSubscriptions) forControlEvents:UIControlEventTouchUpInside];

    self.TV_subscriptions.scrollEnabled = false;
    self.TV_consumeables.scrollEnabled = false;
}

- (void) manageSubscriptions
{
    NSURL * const url = [NSURL URLWithString:[[PEXPaymentManager instance]getSubscriptionManagementUrlString]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void) layoutAll
{
    [PEXGVU scaleFull:self.V_scroller];

    const CGFloat width = self.mainView.frame.size.width;
    const CGFloat margin = PEXVal(@"dim_size_large");
    const CGFloat padding = PEXVal(@"dim_size_medium");
    const CGFloat componentWidth = width - (2 * margin);

    [PEXGVU moveToTop:self.L_subscriptionsSummary  withMargin: margin];
    [PEXGVU scaleHorizontally:self.L_subscriptionsSummary];
    [self.L_subscriptionsSummary setPaddingTop:0.0f left:padding bottom:0.0f rigth:padding];
    [self.L_subscriptionsSummary sizeToFit];


    [PEXGVU scaleHorizontally:self.TV_subscriptions];
    [self.TV_subscriptions sizeToFit];
    [PEXGVU move:self.TV_subscriptions below:self.L_subscriptionsSummary];

    [PEXGVU scaleHorizontally:self.B_manageSubscriptions withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_manageSubscriptions below:self.TV_subscriptions withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.line];
    [PEXGVU move: self.line below: self.B_manageSubscriptions withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU move:self.L_consumeableSummary below:self.line withMargin: margin];
    [PEXGVU scaleHorizontally:self.L_consumeableSummary];
    [self.L_consumeableSummary setPaddingTop:0.0f left:padding bottom:0.0f rigth:padding];
    [self.L_consumeableSummary sizeToFit];

    [PEXGVU scaleHorizontally:self.TV_consumeables];
    [self.TV_consumeables sizeToFit];
    [PEXGVU move:self.TV_consumeables below:self.L_consumeableSummary];

    self.V_scroller.contentSize = CGSizeMake(self.V_scroller.contentSize.width,
            self.TV_consumeables.frame.origin.y + self.TV_consumeables.frame.size.height);
}

- (void)initLayout
{
    [super initLayout];

    [self layoutAll];
}


- (void)initState
{
    [super initState];

    self.queue = dispatch_queue_create("iap items loading queue", nil);

    [self loadCurrentPermissionsAsync];
}

- (void)loadCurrentPermissionsAsync
{
    dispatch_async(self.queue, ^{
        [[[PEXService instance] licenceManager] addListenerAndSet:self];
    });
}

- (void)dismissWithCompletion:(void (^)(void))completion animation:(void (^)(void))animation {

    [[[PEXService instance] licenceManager] removeListener:self];

    [super dismissWithCompletion:completion animation:animation];
}

- (void)permissionsChanged:(NSArray *const)permissions
{
    NSDictionary * consumedSummary = nil;
    NSDictionary * subscriptionsSummary = nil;
    [PEXPermissionsUtils processPermissions:permissions
                             toConsumeables:&consumedSummary
                           toSubscriptionss:&subscriptionsSummary zeroIfNone:false skipDefault:false];

    self.consumedSummary = consumedSummary;
    self.subscriptionsSummary = subscriptionsSummary;

    NSMutableSet * licIds = [[NSMutableSet alloc] init];

    // Is license refresh required?
    if (subscriptionsSummary != nil && [subscriptionsSummary count] > 0){
        for (NSNumber * const key in subscriptionsSummary) {
            NSArray *const subPerm = subscriptionsSummary[key];
            for (PEXDbAccountingPermission * perm in subPerm) {
                if (perm != nil && perm.licId != nil) {
                    [licIds addObject:perm.licId];
                }
            }
        }
    }

    [self loadLicenseAsync:[licIds allObjects]];
    [self refreshDisplay];
}

-(void) refreshDisplay {
    WEAKSELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf applySubscriptions:weakSelf.subscriptionsSummary];
        [weakSelf applyConsumeables:[weakSelf.consumedSummary allValues]];
        [weakSelf layoutAll];
    });
}

- (void)applySubscriptions:(NSDictionary *)subscriptions
{
    PEXGuiDetailsTextBuilder * const builder = [[PEXGuiDetailsTextBuilder alloc] init];


    if (subscriptions && subscriptions.count)
    {
        NSArray * const keys = [subscriptions allKeys];

        int helper = 0;

        for (NSNumber * const key in keys)
        {
            NSArray * const permissions = subscriptions[key];
            if (permissions == nil || [permissions count] == 0){
                continue;
            }

            const PEXDbAccountingPermission * const firstPermission = permissions[0];

            // Product names
            BOOL hasName = NO;
            NSDictionary * lic = self.licenses != nil ? self.licenses[firstPermission.licId] : nil;
            if (lic != nil && ![PEXUtils isEmpty:lic[@"display_name"]]){
                if (helper != 0){
                    [builder appendValue:@"" first:NO];
                }

                [builder appendValue:lic[@"display_name"]
                               first:helper==0
                            fontSize:nil
                           fontColor:PEXCol(@"orange_normal")];

                [builder appendValue:@"" first:NO];
                hasName = YES;
                ++helper;
            }

            NSString * label = nil;
            if ([firstPermission.validTo timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970] + 10ll*PEX_YEAR_IN_SECONDS){
                label = [NSString stringWithFormat:@"%@: %@",
                                PEXStrU(@"L_valid_until"), PEXStrU(@"L_forever")];
            } else {
                label = [NSString stringWithFormat:@"%@: %@",
                                PEXStrU(@"L_valid_until"), [PEXDateUtils dateToFullDateString:firstPermission.validTo]];
            }

            if (helper && !hasName)
                [builder appendLabel:label];
            else
                [builder appendFirstLabel:label];

            [self permissionsDescription:permissions forBuilder:builder];
            ++helper;
        }
    }
    else
    {
        [builder appendFirstLabel:PEXStr(@"L_no_packages_owned")];
    }

    NSAttributedString * const attr = builder.result;

    [self.TV_subscriptions setAttributedText:attr];
}

- (NSInteger) getSortOrder: (PEXDbAccountingPermission *) perm{
    if ([PEX_PERMISSION_CALLS_LIMIT_NAME isEqualToString:perm.name]){
        return PEX_PACKAGE_ITEM_SORT_CALL_SECONDS;
    } else if ([PEX_PERMISSION_MESSAGES_LIMIT_NAME isEqualToString:perm.name]){
        return PEX_PACKAGE_ITEM_SORT_MESSAGES_COUNT;
    } else if ([PEX_PERMISSION_MESSAGES_DAILY_NAME isEqualToString:perm.name]){
        return PEX_PACKAGE_ITEM_SORT_MESSAGES_DAILY_COUNT;
    } else if ([PEX_PERMISSION_FILES_LIMIT_NAME isEqualToString:perm.name]){
        return PEX_PACKAGE_ITEM_SORT_FILES_COUNT;
    } else {
        return PEX_PACKAGE_ITEM_SORT_UNKNOWN;
    }
}

- (void) permissionsDescription: (NSArray *) permissions
                           forBuilder: (PEXGuiDetailsTextBuilder * const) builder
{
    bool containsMessagesDailyLimit = false;
    bool containsMessagesDailyLimitIsUnlimited = false;
    bool containsMessagesDifferentLimit = false;
    bool containsMessagesDifferentLimitIsUnlimited = false;
    bool containsFilesLimit = false;
    bool containsFilesUnlimited = false;

    for (const PEXDbAccountingPermission *const permission in permissions) {
        if ([permission.name isEqualToString:PEX_PERMISSION_MESSAGES_DAILY_NAME]) {
            containsMessagesDailyLimit = true;
            if ([permission.value isEqualToNumber:@(-1)])
                containsMessagesDailyLimitIsUnlimited = true;

        } else if ([PEXPermissionsUtils isPermissionForMessages:permission.name]) {

            containsMessagesDifferentLimit = true;
            if ([permission.value isEqualToNumber:@(-1)])
                containsMessagesDifferentLimitIsUnlimited = true;

        } else if ([PEXPermissionsUtils isPermissionForFiles: permission.name]) {
            containsFilesLimit = true;
            if ([permission.value isEqualToNumber:@(-1)])
                containsFilesUnlimited = true;
        }
    }

    // Sort permissions according to the sort order.
    WEAKSELF;
    permissions = [permissions sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSInteger s1 = [weakSelf getSortOrder:(PEXDbAccountingPermission*)a];
        NSInteger s2 = [weakSelf getSortOrder:(PEXDbAccountingPermission*)b];
        if (s1==s2){
            return NSOrderedSame;
        }
        return s1 < s2 ? NSOrderedAscending : NSOrderedDescending;
    }];

    for (const PEXDbAccountingPermission *const permission in permissions)
    {
        NSString * const permissionName = permission.name;
        const int64_t valueInt = [permission.value longLongValue];
        NSString *productDesc;
        NSString *productValue;

        if ([permissionName isEqualToString:PEX_PERMISSION_MESSAGES_DAILY_NAME])
        {
            if (containsMessagesDifferentLimitIsUnlimited)
                continue;

            productDesc = PEXStrU(@"L_messages_daily_limit");
            productValue = containsMessagesDailyLimitIsUnlimited ? PEXStrU(@"L_unlimited") :
                    [NSString stringWithFormat:@"%lld", valueInt];
        }
        else if ([permissionName isEqualToString:PEX_PERMISSION_MESSAGES_LIMIT_NAME])
        {
            productDesc = PEXStrU(@"L_messages");
            productValue = containsMessagesDifferentLimitIsUnlimited ? PEXStr(@"L_unlimited") :
                    [NSString stringWithFormat:@"%lld / %lld",
                                    valueInt - [permission.spent longLongValue], valueInt];
        }
        else if ([permissionName isEqualToString:PEX_PERMISSION_CALLS_LIMIT_NAME])
        {
            productDesc = PEXStrU(@"L_calls");
            productValue = [permission.value isEqualToNumber: @(-1)] ? PEXStr(@"L_unlimited") :
            [NSString stringWithFormat:@"%@ / %@",
                                                      [PEXGuiCallController getTimeIntervalStringFromTime:valueInt - [permission.spent longLongValue]],
                                                      [PEXGuiCallController getTimeIntervalStringFromTime:valueInt]];
        }
        else if ([permissionName isEqualToString:PEX_PERMISSION_FILES_LIMIT_NAME])
        {
            productDesc = PEXStrU(@"L_files");
            productValue = containsFilesUnlimited ? PEXStr(@"L_unlimited") :
                    [NSString stringWithFormat:@"%lld / %lld",
                                    valueInt - [permission.spent longLongValue], valueInt];
        }

        if (productDesc && valueInt)
        {
            [builder appendValue:[NSString stringWithFormat:@"%@: %@", productDesc, productValue]];
        }
    }
}

- (void) appendValueForBuilder: (PEXGuiDetailsTextBuilder * const) builder
                 forPermission: (const PEXDbAccountingPermission * const) permission
                      withName: (NSString * const) name
{
    [builder appendValue:[NSString stringWithFormat:@"%@: %lld / %lld",
                    name, [permission.value longLongValue] - [permission.spent longLongValue], [permission.value longLongValue]]];
}

- (void)applyConsumeables: (NSArray * const) packages
{
    PEXGuiDetailsTextBuilder * const builder = [[PEXGuiDetailsTextBuilder alloc] init];

    if (packages && packages.count)
    {
        NSString * const first = [PEXPackageHumanDescription getApproprietText:packages[0]];
        [builder appendFirstValue:first];

        for (NSUInteger i = 1; i < packages.count; ++i)
        {
            [builder appendValue:[PEXPackageHumanDescription getApproprietText:packages[i]]];
        }
    }
    else
    {
        [builder appendFirstLabel:PEXStr(@"L_no_consumeables")];
    }

    NSAttributedString * const attr = builder.result;

    [self.TV_consumeables setAttributedText:attr];
}

- (void)loadLicenseAsync: (NSArray *) licenseIds
{
    if (licenseIds == nil || [licenseIds count] == 0){
        DDLogVerbose(@"Empty license id list, no refresh");
        return;
    }

    BOOL doRefresh = self.licenses == nil || [self.licenses count] > 0;
    if (!doRefresh){
        for(NSNumber * licId in licenseIds){
            if (self.licenses[licId] == nil){
                doRefresh = YES;
                break;
            }
        }
    }

    if (!doRefresh){
        DDLogVerbose(@"No license refresh needed");
        return;
    }

    self.licLoader = [[PEXLicenseLoader alloc] init];

    WEAKSELF;
    PEXLicenseLoadFailed failureBlock = ^{
        [weakSelf itemsLoadingFailed];
    };

    PEXLicenseLoadFinished successBlock = ^(NSDictionary *licenses) {
        [weakSelf itemsLoadSucceeded:licenses];
    };

    // Start async request.
    @try {
        const bool success = [self.licLoader loadItemsCompletion:licenseIds completion:successBlock errorHandler:failureBlock];
        if (!success) {
            DDLogError(@"Could not load license details");
        }
    } @catch(NSException * e){
        DDLogError(@"Exception when loading license details %@", e);
    }
}

- (void) itemsLoadSucceeded: (NSDictionary * const) licenses
{
    self.licenses = licenses;
    [self itemsLoadingEnded];
}

- (void) itemsLoadingFailed
{
    [self itemsLoadingEnded];
}

- (void) itemsLoadingEnded
{
    self.licLoader = nil;
    [self refreshDisplay];
}

@end