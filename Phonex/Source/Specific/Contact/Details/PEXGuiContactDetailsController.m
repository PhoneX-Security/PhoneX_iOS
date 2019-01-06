//
//  PEXGuiContactDetails.m
//  Phonex
//
//  Created by Matej Oravec on 12/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXGuiContactDetailsController.h"
#import "PEXGuiController_Protected.h"

#import "PEXDbContact.h"
#import "PEXGuiDetailView.h"
#import "PEXGuiLinearScrollingView.h"

#import "PEXDbCursor.h"
#import "PEXDbAppContentProvider.h"

#import "PEXGuiContactDetailsController.h"
#import "PEXGuiButtonMain.h"
#import "PEXCheckCertificateExecutor.h"
#import "PEXContactCertificateLoadTask.h"
#import "PEXGuiLinearRollingView.h"
#import "PEXGuiBackgroundView.h"
#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXCheckCertificateTask.h"
#import "PEXGuiPoint.h"
#import "PEXGuiClassicLabel.h"
#import "PEXPEXGuiCertificateTextBuilder.h"
#import "PEXGuiRenameContactController.h"
#import "PEXReport.h"
#import "UITextView+PEXPaddings.h"

@interface PEXGuiContactDetailsController ()

@property (nonatomic) PEXDbContact * contact;
@property (nonatomic) PEXGuiLinearScrollingView * linearView;
@property (nonatomic) PEXGuiDetailView * aliasView;
@property (nonatomic) PEXGuiDetailView * sipView;
@property (nonatomic) PEXGuiNavigationController * parentNavigation;

@property (nonatomic) PEXGuiPoint * line;
@property (nonatomic) UIView * V_certificateTitle;
@property (nonatomic) PEXGuiBaseLabel *L_certificateTitle;

@property (nonatomic) UIButton * B_recheckCertificate;
@property (nonatomic) PEXContactCertificateLoadTask * certificateDetailsTask;
@property (nonatomic) PEXGuiLinearRollingView * V_certificateDetailsContainer;
@property (nonatomic) PEXGuiActivityIndicatorView * V_indicator;
@property (nonatomic) PEXGuiReadOnlyTextView * TV_certificateDetails;

@end

@implementation PEXGuiContactDetailsController

- (id) initWithContact: (PEXDbContact * const) contact
{
    self = [super init];

    self.contact = contact;

    return self;
}

- (void) setNavigationParent: (PEXGuiNavigationController *) navigation
{
    self.parentNavigation = navigation;
}

// must be called in mutex
- (void) loadContact
{
    PEXDbCursor * const cursor = [self loadContactFromDb];

    if (cursor && [cursor moveToNext])
    {
        self.contact = [PEXDbContact contactFromCursor:cursor];
        [self setContactDetails];
    }
}

- (const UIView *) getContentView
{
    return self.linearView;
}

- (void) loadContent
{
    [self loadContact];
}

- (void) setContactDetails
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.aliasView setValue:self.contact.displayName];
        [self.sipView setValue:self.contact.sip];

        [self.parentNavigation setLabelText:self.contact.displayName];
    });
}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"ContactDetails";

    self.linearView = [[PEXGuiLinearScrollingView alloc] init];
    [self.mainView addSubview:self.linearView];

    [PEXGVU executeWithoutAnimations:^{
        self.aliasView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.aliasView];

        self.sipView = [[PEXGuiDetailView alloc] init];
        [self.linearView addView:self.sipView];

        self.line = [[PEXGuiPoint alloc] initWithColor:PEXCol(@"light_gray_high")];
        [self.linearView addView:self.line];

        self.V_certificateTitle = [[UIView alloc] init];
        [PEXGVU setHeight: self.V_certificateTitle
                       to: self.L_certificateTitle.frame.size.height + 2 * PEXVal(@"dim_size_large")];
        [self.linearView addView:self.V_certificateTitle];

        self.L_certificateTitle = [[PEXGuiClassicLabel alloc]
                initWithFontSize:PEXVal(@"dim_size_small_medium")
                       fontColor:PEXCol(@"light_gray_low")];
        [self.V_certificateTitle addSubview:self.L_certificateTitle];

        self.B_recheckCertificate = [[PEXGuiButtonMain alloc] init];
        [self.linearView addView:self.B_recheckCertificate];

        /*
        self.V_certificateDetailsContainer = [[PEXGuiLinearRollingView alloc] init];
        [self.linearView addView:self.V_certificateDetailsContainer];
        */

        self.TV_certificateDetails = [[PEXGuiReadOnlyTextView alloc] init];
        [self.linearView addView:self.TV_certificateDetails];

        self.V_indicator = [[PEXGuiActivityIndicatorView alloc] init];
        [self.linearView addSubview:self.V_indicator];
    }];
}


- (void) initContent
{
    [super initContent];

    [self.aliasView setName:PEXStrU(@"L_alias")];
    [self.aliasView setValue:PEXDefaultStr];

    [self.sipView setName:PEXStrU(@"L_username")];
    [self.sipView setValue:PEXDefaultStr];

    self.L_certificateTitle.text = PEXStrU(@"L_certificate_title");

    [self.B_recheckCertificate setTitle:PEXStrU(@"L_recheck_certificate") forState:UIControlStateNormal];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleFull:self.linearView];

    [PEXGVU scaleHorizontally:self.aliasView];
    [PEXGVU scaleHorizontally:self.sipView];

    [PEXGVU scaleHorizontally:self.line];
    [PEXGVU scaleHorizontally: self.V_certificateTitle];

    [PEXGVU center:self.L_certificateTitle];

    [PEXGVU scaleHorizontally:self.B_recheckCertificate withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally: self.TV_certificateDetails withMargin:PEXVal(@"dim_size_medium")];
    [self.TV_certificateDetails setPaddingNumTop:nil left:@(0.0f) bottom:nil rigth:@(0.0f)];

    [PEXGVU move: self.V_indicator below:self.B_recheckCertificate withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU centerHorizontally:self.V_indicator];
}

- (void) initBehavior
{
    [super initBehavior];

    [self.sipView setEnabled:false];
    [self.aliasView addAction:self action:@selector(renameContactDialog)];

    [self.B_recheckCertificate addTarget:self action:@selector(recheckCertificate:)
                        forControlEvents:UIControlEventTouchUpInside];

    [self.TV_certificateDetails setScrollEnabled:false];
}

- (IBAction) recheckCertificate: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_RECHECK_CERTIFICATE];
    [self showLoadingCertificate];
    PEXCheckCertificateExecutor * executor = [[PEXCheckCertificateExecutor alloc] init];
    executor.parentController = self;
    executor.contact = self.contact;
    [executor show];
}

- (void) renameContactDialog
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CONTACT_DETAILS_RENAME_CONTACT];
    [PEXGuiRenameContactController showRenameControllerWithUsername:self.contact.sip
                                                              alias:self.contact.displayName
                                                          forParent:self];
}

// OBSERVER STUFF
- (bool) deliverSelfNotifications
{
    return true;
}

- (void) dispatchChange: (const bool) selfChange
                    uri: (const PEXUri *) uri
{
    // not implemented
}

// must call mutex
- (void) dispatchChangeDelete: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContact getURI]])
        return;

    PEXDbCursor * const cursor = [self loadContactFromDb];

    if (cursor && ([cursor getCount] == 0))
    {
        // THE CONTACT WAS DELETED BUT WE DO NOTHING ABOUT IT ... TODO
        /*
        [self.contentLock lock];
        dispatch_async(dispatch_get_main_queue(), ^(void)
                       {
                           // DISMISS (set/unset/lock/unlock)
                       });
         */
    }
}

- (void) dispatchChangeUpdate: (const bool) selfChange
                          uri: (const PEXUri * const) uri
{
    if (![uri isEqualToUri:[PEXDbContact getURI]])
        return;

    PEXDbCursor * const cursor = [self loadContactFromDb];

    if (cursor && [cursor moveToNext])
    {
        PEXDbContact * const updateContact = [PEXDbContact contactFromCursor:cursor];

        [self.contentLock lock];
        if ([self needsToUpdate:updateContact])
        {
            self.contact = updateContact;
            [self setContactDetails];
        }
        [self.contentLock unlock];
    }

}

- (PEXDbCursor *) loadContactFromDb
{
    return [[PEXDbAppContentProvider instance]query:[PEXDbContact getURI]
                                         projection:[PEXDbContact getLightProjection]
                                          selection:[NSString stringWithFormat:@"WHERE %@=?", DBCL(FIELD_SIP)]
                                      selectionArgs:@[self.contact.sip]
                                          sortOrder:nil];
}

- (bool) needsToUpdate: (const PEXDbContact * const) updateContact
{
    if (self.contact.sip != updateContact.sip) return true;
    if (self.contact.displayName != updateContact.displayName) return true;

    return false;
}

- (void) initState
{
    [super initState];

    self.certificateDetailsTask = [[PEXContactCertificateLoadTask alloc] init];
    [self.certificateDetailsTask addListener:self];
    self.certificateDetailsTask.userName = self.contact.sip;

    [self loadCertificateAsync];
}

- (void) loadCertificateAsync
{
    [self showLoadingCertificate];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{;

        [self.certificateDetailsTask start];
    });
}

- (void) showLoadingCertificate
{
    [self showLoading:true];
}

- (void) showCertificateDetails
{
    [self showLoading:false];
}

- (void) showLoading: (const bool) loading
{
    if (loading)
        [self.V_indicator startAnimating];
    else
        [self.V_indicator stopAnimating];

    [self.V_indicator setHidden:!loading];
    [self.TV_certificateDetails setHidden:loading];
}

- (void) setCertificateDetails: (const PEXCertDetails * const) details
{
    PEXGuiDetailsTextBuilder * const builder = [[PEXGuiDetailsTextBuilder alloc] init];

    [builder appendFirstLabel:PEXStrU(@"L_certificate_status")];
    [builder appendValue:[self getCertificateStatusDescription:details.certStatus]];

    [builder appendLabel:PEXStrU(@"L_certificate_created")];
    [builder appendValue:[PEXDateUtils dateToFullDateString:details.dateCreated]];

    [builder appendLabel:PEXStrU(@"L_certificate_last_refresh")];
    [builder appendValue:[PEXDateUtils dateToFullDateString:details.dateLastRefresh]];

    [builder appendLabel:PEXStrU(@"L_certificate_hash")];
    [builder appendValue:details.certHash];

    [builder appendLabel:PEXStrU(@"L_certificate_not_before")];
    [builder appendValue:[PEXDateUtils dateToFullDateString:details.notBefore]];

    [builder appendLabel:PEXStrU(@"L_certificate_not_after")];
    [builder appendValue:[PEXDateUtils dateToFullDateString:details.notAfter]];

    [builder appendLabel:PEXStrU(@"L_certificate_cn")];
    [builder appendValue:details.certCN];

    [self setCertificateText:builder.result];
}

- (void) setCertificateText: (NSAttributedString * const) text
{
    // because of step from error to normal
    [PEXGVU scaleHorizontally: self.TV_certificateDetails withMargin:PEXVal(@"dim_size_medium")];
    [self.TV_certificateDetails setPaddingNumTop:nil left:@(0.0f) bottom:nil rigth:@(0.0f)];

    [self.linearView removeView:self.TV_certificateDetails];
    [self.TV_certificateDetails setAttributedText:text];
    [self.TV_certificateDetails sizeToFit];
    [self.linearView addView:self.TV_certificateDetails];
}

- (void)taskStarted:(const PEXTaskEvent *const)event {

}

- (void)taskEnded:(const PEXTaskEvent *const)event {

    dispatch_sync(dispatch_get_main_queue(), ^{
        [self setCertificateDetails:self.certificateDetailsTask.certDetails];
        [self showCertificateDetails];
    });
}

- (void) showError
{
    [self setCertificateText:[[NSAttributedString alloc] initWithString: PEXStrU(@"title_error")]];
    [self showCertificateDetails];
}

- (NSString *) getCertificateStatusDescription: (const NSInteger) status
{
    NSString * result;

    switch (status)
    {
        case 1: result = PEXStr(@"L_certificate_status_ok"); break;
        case 2: result = PEXStr(@"L_certificate_status_invalid"); break;
        case 3: result = PEXStr(@"L_certificate_status_revoked"); break;
        case 4: result = PEXStr(@"L_certificate_status_forbidden"); break;
        case 5: result = PEXStr(@"L_certificate_status_missing"); break;
        case 6: result = PEXStr(@"L_certificate_status_no_such_user"); break;
        default: result = PEXStr(@"title_error"); break;
    }

    return result;
}

- (void)taskProgressed:(const PEXTaskEvent *const)event {

}

- (void)taskCancelStarted:(const PEXTaskEvent *const)event {

}

- (void)taskCancelEnded:(const PEXTaskEvent *const)event {

}

- (void)taskCancelProgressed:(const PEXTaskEvent *const)event {

}

@end
