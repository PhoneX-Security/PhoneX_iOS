//
// Created by Matej Oravec on 19/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiCreateAccountController.h"
#import "PEXGuiController_Protected.h"

#import "PEXGuiActivityIndicatorView.h"
#import "PEXGuiReadOnlyTextView.h"
#import "PEXGuiTextFIeld.h"
#import "PEXGuiImageView.h"
#import "PEXGuiClickableView.h"
#import "PEXGuiButtonMain.h"

#import "PEXCaptchaLoader.h"
#import "PEXGuiUtils.h"
#import "PEXGuiPhonexCheckBox.h"
#import "PEXGuiClassicLabel.h"
#import "PEXGuiUnaryDialogExecutor.h"
#import "PEXGuiUnaryDialogExecutor_Protected.h"
#import "PEXStringUtils.h"
#import "PEXRegex.h"
#import "PEXCreateAccountTask.h"
#import "PEXCreateAccountHolder.h"
#import "PEXCreateAccountExecutor.h"
#import "PEXGuiFactory.h"
#import "PEXGuiScanController.h"
#import "PEXReport.h"
#import "AJWValidator.h"
#import "PEXLoginNameValidator.h"
#import "PEXService.h"
#import "PEXProductCodeValidator.h"
#import "PEXCaptchaValidator.h"

const static CGFloat S_CAPTCHA_HEIGHT = 80;
static NSString * const S_CHARACTERS = @"abcdefghjklmnpqrstuvwxyz23456789";

@interface PEXGuiCreateAccountController () <AJWValidatorDelegate>

@property (nonatomic) PEXGuiTextField * TF_username;

@property (nonatomic) PEXGuiTextField * TF_captcha;

@property (nonatomic) UIImageView * I_captacha;
@property (nonatomic) UILabel * L_tapToReload;
@property (nonatomic) PEXGuiClickableView * B_reload;

@property (nonatomic) UIButton * B_create_new_account;

@property (nonatomic) PEXCaptchaLoader * captchaLoader;

#ifdef PEX_ALLOW_PRODUCT_CODE
@property (nonatomic) UILabel * L_insertProductCode;
@property (nonatomic) PEXGuiClickableView * B_insertProductCodeWrapper;
@property (nonatomic) PEXGuiPhonexCheckBox * CB_insertProductCode;

@property (nonatomic) UITextField * TF_productCode;
#endif

@property (nonatomic) PEXGuiActivityIndicatorView * loadingIndicator;
@property (nonatomic) AJWValidator * validatorLogin;
@property (nonatomic) AJWValidator * validatorProductCode;
@property (nonatomic) AJWValidator * validatorCaptcha;

@end

@implementation PEXGuiCreateAccountController {

}

- (void) initGuiComponents
{
    [super initGuiComponents];
    self.screenName = @"CreateAccount";

    self.TF_captcha = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_captcha];

    self.TF_username = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_username];

    self.B_reload= [[PEXGuiClickableView alloc] init];
    [self.mainView addSubview:self.B_reload];

    self.B_create_new_account= [[PEXGuiButtonMain alloc] init];
    [self.mainView addSubview:self.B_create_new_account];

    self.I_captacha = [[UIImageView alloc] init];
    [self.mainView addSubview:self.I_captacha];

#ifdef PEX_ALLOW_PRODUCT_CODE
    self.CB_insertProductCode = [[PEXGuiPhonexCheckBox alloc] init];
    [self.mainView addSubview:self.CB_insertProductCode];

    self.B_insertProductCodeWrapper = [[PEXGuiClickableView alloc] init];
    [self.mainView addSubview:self.B_insertProductCodeWrapper];

    self.L_insertProductCode = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"black_normal")];
    [self.mainView addSubview:self.L_insertProductCode];

    self.TF_productCode = [[PEXGuiTextField alloc] init];
    [self.mainView addSubview:self.TF_productCode];
#endif

    self.loadingIndicator = [[PEXGuiActivityIndicatorView alloc] init];
    [self.mainView addSubview:self.loadingIndicator];

    self.L_tapToReload = [[PEXGuiClassicLabel alloc]
            initWithFontSize:PEXVal(@"dim_size_small_medium")
                   fontColor:PEXCol(@"black_normal")];
    [self.mainView addSubview:self.L_tapToReload];
}

- (void) initContent
{
    [super initContent];

    self.TF_username.placeholder = PEXStr(@"L_username");

    self.TF_captcha.placeholder = PEXStr(@"L_captcha_here");

    [self.B_create_new_account setTitle:PEXStrU(@"B_create_account") forState:UIControlStateNormal];

#ifdef PEX_ALLOW_PRODUCT_CODE
    self.L_insertProductCode.text = PEXStr(@"L_i_have_product_code");
    self.TF_productCode.placeholder = PEXStr(@"L_product_code_here");
#endif

    self.L_tapToReload.text = PEXStr(@"L_tap_to_reload");
}

- (void) initBehavior
{
    [super initBehavior];
    WEAKSELF;

    [self.TF_username setDelegate:self];
    [self.TF_captcha setDelegate:self];
    self.TF_username.autocapitalizationType = UITextAutocapitalizationTypeNone;

#ifdef PEX_ALLOW_PRODUCT_CODE
    [self.TF_productCode setDelegate:self];
    self.CB_insertProductCode.checkBlock = ^(const bool isChecked) {
        [PEXReport logUsrButton:PEX_EVENT_BTN_HAS_PRODUCT_CODE];
        [weakSelf checkSet:isChecked];
    };

    [self.B_insertProductCodeWrapper addAction:self action:@selector(productCodeClicked:)];
#endif

    [self.B_reload addActionBlock:^{

        /*
        PEXGuiScanController * const scanner = [[PEXGuiScanController alloc] init];
        [scanner showInNavigation:self title:@"scanner"];
        */
        [PEXReport logUsrButton:PEX_EVENT_BTN_CAPTCHA_RELOAD];
        [weakSelf reloadCaptcha];
    }];

    [self.B_create_new_account addTarget:self
                                  action:@selector(createClicked:)
                        forControlEvents:UIControlEventTouchUpInside];

    self.validatorLogin = [PEXLoginNameValidator initValidatorWithDomain:NO];
    self.validatorProductCode = [PEXProductCodeValidator initValidator];

    [self.TF_username ajw_attachValidator:self.validatorLogin];
    [self.TF_username addTarget:self action:@selector(usernameTextChanged:) forControlEvents:UIControlEventEditingChanged];

#ifdef PEX_ALLOW_PRODUCT_CODE
    [self.TF_productCode ajw_attachValidator:self.validatorProductCode];
    [self.TF_productCode addTarget:self action:@selector(productCodeChanged:) forControlEvents:UIControlEventEditingChanged];
    [self.TF_productCode setDelegate:self];
#endif

    [self.TF_captcha addTarget:self action:@selector(captchaChanged:) forControlEvents:UIControlEventEditingChanged];

    _validatorLogin.validatorStateChangedHandler = ^(AJWValidatorState newState) {
        switch (newState) {
            case AJWValidatorValidationStateValid: {
                [weakSelf handleValidLogin];
                break;
            }
            case AJWValidatorValidationStateInvalid: {
                [weakSelf handleInvalidLogin];
                break;
            }
            default:
                break;
        }
    };

    _validatorProductCode.validatorStateChangedHandler = ^(AJWValidatorState newState) {
        switch (newState) {
            case AJWValidatorValidationStateValid: {
                [weakSelf handleValidProductCode];
                break;
            }
            case AJWValidatorValidationStateInvalid: {
                [weakSelf handleInvalidProductCode];
                break;
            }
            default:
                break;
        }
    };
}

- (IBAction) productCodeClicked: (id) sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_PRODUCT_CODE];
#ifdef PEX_ALLOW_PRODUCT_CODE
    [self.CB_insertProductCode setChecked:!self.CB_insertProductCode.isChecked];
#endif
}

- (void) checkSet: (const bool) isChecked
{
#ifdef PEX_ALLOW_PRODUCT_CODE
    [self.TF_productCode setEnabled:isChecked];
#endif
}

- (void) initState
{
#ifdef PEX_ALLOW_PRODUCT_CODE
    [self.TF_productCode setEnabled:false];
#endif
    [PEXReport logEventAsync:PEX_EVENT_NEW_ACCOUNT_SCREEN];
}

- (void) initLayout
{
    [super initLayout];

    [PEXGVU scaleHorizontally:self.TF_username withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU moveToTop:self.TF_username withMargin:PEXVal(@"dim_size_large")];

#ifdef PEX_ALLOW_PRODUCT_CODE
    [PEXGVU setSize:self.CB_insertProductCode x:PEXVal(@"dim_size_large") y:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.CB_insertProductCode below:self.TF_username withMargin:PEXVal(@"dim_size_small")];
    [PEXGVU moveToLeft:self.CB_insertProductCode withMargin:PEXVal(@"dim_size_large")];

    [PEXGVU scaleHorizontally:self.TF_productCode withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_productCode below:self.CB_insertProductCode withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU centerVertically:self.L_insertProductCode on:self.CB_insertProductCode];
    [PEXGVU move:self.L_insertProductCode rightOf:self.CB_insertProductCode withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU setHeight:self.I_captacha to: S_CAPTCHA_HEIGHT];
    [PEXGVU scaleHorizontally: self.I_captacha withMargin: PEXVal(@"dim_size_large")];
    [PEXGVU move:self.I_captacha below:self.TF_productCode withMargin:PEXVal(@"dim_size_small")];
#else
    [PEXGVU setHeight:self.I_captacha to: S_CAPTCHA_HEIGHT];
    [PEXGVU scaleHorizontally: self.I_captacha withMargin: PEXVal(@"dim_size_large")];
    [PEXGVU move:self.I_captacha below:self.TF_username withMargin:PEXVal(@"dim_size_small")];
#endif
    [PEXGVU centerHorizontally:self.L_tapToReload];
    [PEXGVU move:self.L_tapToReload below:self.I_captacha withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.TF_captcha withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.TF_captcha below:self.L_tapToReload withMargin:PEXVal(@"dim_size_small")];

    [PEXGVU scaleHorizontally:self.B_create_new_account withMargin:PEXVal(@"dim_size_large")];
    [PEXGVU move:self.B_create_new_account below:self.TF_captcha withMargin:PEXVal(@"dim_size_small")];

    // remember user check box wrapper
#ifdef PEX_ALLOW_PRODUCT_CODE
    const CGFloat upperY = self.TF_username.frame.origin.y + self.TF_username.frame.size.height;
    const CGFloat leftX = self.CB_insertProductCode.frame.origin.x;

    self.B_insertProductCodeWrapper.frame = CGRectMake(0.0f /*leftX*/,
            upperY,

            self.L_insertProductCode.frame.origin.x +
                    self.L_insertProductCode.frame.size.width /*- leftX*/,

            self.TF_productCode.frame.origin.y - upperY
    );
    [self.view bringSubviewToFront:self.B_insertProductCodeWrapper];
#endif

    [PEXGVU center:self.loadingIndicator in:self.I_captacha];
    self.B_reload.frame = self.I_captacha.frame;
    [self.mainView bringSubviewToFront:self.B_reload];
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [self reloadCaptcha];
}

- (void) setCaptchaImage : (UIImage * const) image
{
    [self.I_captacha setHidden:false];
    [self.loadingIndicator setHidden:true];

    [self.I_captacha setImage:image];
    [self.loadingIndicator stopAnimating];

    [self.TF_captcha setEnabled:true];
    self.TF_captcha.text = @"";
    [self.B_reload setHidden:false];
    [self.L_tapToReload setHidden:false];
    [self.B_create_new_account setEnabled:true];
}

- (void)showErrorState
{
    [self.loadingIndicator stopAnimating];
    [self.I_captacha setHidden:true];
    [self.B_reload setHidden:false];
    [self.L_tapToReload setHidden:false];
    [self.B_create_new_account setEnabled:false];

    [self showErrorMessage:PEXStr(@"msg_error_loading_captcha")];
}

- (void)showErrorMessage: (NSString * const) errorText
{
    [PEXGuiFactory showErrorTextBox:self withText:errorText];

    /*
    PEXGuiUnaryDialogExecutor * const dialogExecutor = [[PEXGuiUnaryDialogExecutor alloc] initWithController:self];
    dialogExecutor.text = errorText;
    [dialogExecutor show];
    */
}

- (void) showLoading
{
    [self.B_reload setHidden:true];
    [self.I_captacha setHidden:true];
    [self.loadingIndicator setHidden:false];

    [self.loadingIndicator startAnimating];
    [self.TF_captcha setEnabled:false];
    self.TF_captcha.text = @"";
    [self.L_tapToReload setHidden:true];
    [self.B_create_new_account setEnabled:false];
}

- (void) reloadCaptcha
{
    [self showLoading];

    self.captchaLoader = [[PEXCaptchaLoader alloc] init];
    if ([self.captchaLoader loadCaptchaAsyncForHeight:[PEXGuiUtils pointsToPixels:S_CAPTCHA_HEIGHT]
                                           completion:^(UIImage * const image){
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [self setCaptchaImage:image];
                                               });
                                           }
                                         errorHandler:^{
                                             [self showErrorState];
                                         }])
    {
        DDLogDebug(@"CAPTCHA LOADING INIT OK");
    }
    else
    {
        [self showErrorState];
    }
}

static bool isUsernameValid(NSString *username)
{
    return [PEXLoginNameValidator isUsernameValid:username allowDomain:NO];
}

static bool checkParityForProductCode (NSString * const dashedCode)
{
    NSString * code = [PEXProductCodeValidator sanitize:dashedCode];
    if ([PEXStringUtils isEmpty:code]) {
        return false;
    }

    const int modulo = 29;
    int sum = 0;

    for (int i = 0; i < code.length; ++i)
    {
        const int position = code.length - i - 1;

        NSRange singleRange = {.location = position, .length = 1};
        const NSRange range =
                [S_CHARACTERS rangeOfString:[code substringWithRange:singleRange]];

        if (range.length == NSNotFound)
            return false;

        sum += range.location * (i + 1); // multiply by weight and add to sum
    }

    return (sum % modulo) == 0;
}

// sanitizeInputs must be called before this
- (bool) checkInputsAndGetErrorMessgae
{
    NSString * text;

    // Re-run validators.
    [self.validatorLogin validate:self.TF_username.text];

#ifdef PEX_ALLOW_PRODUCT_CODE
    if (self.CB_insertProductCode.isChecked){
        [self.validatorProductCode validate:self.TF_productCode.text];
    }
#endif

    if (!isUsernameValid(self.TF_username.text))
    {
        text = PEXStr(@"msg_invalid_username");
    }
#ifdef PEX_ALLOW_PRODUCT_CODE
    else if ((self.CB_insertProductCode.isChecked) &&
            !checkParityForProductCode(self.TF_productCode.text))
    {
        text = PEXStr(@"msg_invalid_product_code_hash");
    }
#endif
    else if ([PEXStringUtils isEmpty:self.TF_captcha.text])
    {
        text = PEXStr(@"msg_captcha_is_empty");
    }

    bool result = true;
    if (text)
    {
        result = false;
        [self showErrorMessage:text];
    }

    return result;
}

- (void) sanitizeInputs
{
    [PEXGuiUtils sanitizeTextFieldInputLowerCase:self.TF_username];
    [PEXGuiUtils sanitizeTextFieldInput:self.TF_captcha];

#ifdef PEX_ALLOW_PRODUCT_CODE
    if (self.CB_insertProductCode.isChecked) {
        [self sanitizeProductCode];
    }
#endif
}

- (void) sanitizeProductCode
{
#ifdef PEX_ALLOW_PRODUCT_CODE
    self.TF_productCode.text = [PEXProductCodeValidator formatCode:self.TF_productCode.text];
#endif
}

- (IBAction) createClicked:(id)sender
{
    [PEXReport logUsrButton:PEX_EVENT_BTN_CREATE_ACCOUNT];
    [self sanitizeInputs];

    if (![self checkInputsAndGetErrorMessgae])
        return;

    [self.view endEditing:YES];

    PEXCreateAccountHolder * const holder = [[PEXCreateAccountHolder alloc] init];
    holder.username = self.TF_username.text;
    holder.captcha = self.TF_captcha.text;

#ifdef PEX_ALLOW_PRODUCT_CODE
    if (self.CB_insertProductCode.isChecked)
    {
        holder.productCode = [PEXProductCodeValidator sanitize:self.TF_productCode.text];
    }
#endif

    PEXCreateAccountExecutor * executor = [[PEXCreateAccountExecutor alloc] init];
    executor.holder = holder;
    executor.parentController = self;
    executor.listener = self;
    [executor show];
}

- (void)newAccountCreated:(const PEXNewAccountInfo *const)info
{
    id<PEXNewAccountCreatedListener> listenerRefCopy = self.listener;
    const PEXNewAccountInfo * const infoRefCopy = info;

    [self.fullscreener dismissViewControllerAnimated:true completion:^{
        [listenerRefCopy newAccountCreated:infoRefCopy];
    }];
}

- (IBAction) usernameTextChanged: (UITextField *) sender
{
    if (sender.text.length > 0) {
        sender.text = [PEXLoginNameValidator sanitize:sender.text allowDomain:NO];
        [self.validatorLogin validate:sender.text];
    }
}

- (IBAction) productCodeChanged: (UITextField *) sender
{
    if (sender.text.length > 0) {
        [self.validatorProductCode validate:sender.text];
    }
}

- (IBAction) captchaChanged: (UITextField *) sender
{
    if (sender.text.length > 0) {
        sender.text = [PEXCaptchaValidator sanitize:sender.text];
    }
}

- (void)handleValidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *validGreen = PEXCol(@"green_normal");
        weakSelf.TF_username.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
    }];
}

- (void)handleInvalidLogin
{
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *invalidRed = PEXCol(@"red_normal");
        weakSelf.TF_username.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
    }];
}

- (void)handleValidProductCode
{
#ifdef PEX_ALLOW_PRODUCT_CODE
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *validGreen = PEXCol(@"green_normal");
        weakSelf.TF_productCode.backgroundColor = [validGreen colorWithAlphaComponent:0.3];
    }];
#endif
}

- (void)handleInvalidProductCode
{
#ifdef PEX_ALLOW_PRODUCT_CODE
    WEAKSELF;
    [PEXService executeOnMain:YES block:^{
        UIColor *invalidRed = PEXCol(@"red_normal");
        weakSelf.TF_productCode.backgroundColor = [invalidRed colorWithAlphaComponent:0.3];
    }];
#endif
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
#ifdef PEX_ALLOW_PRODUCT_CODE
    if (textField != self.TF_productCode){
        return YES;
    }

    BOOL result = [PEXProductCodeValidator textField:textField shouldChangeCharactersInRange:range replacementString:string];
    [self.validatorProductCode validate:textField.text];
    return result;
#else
    return YES;
#endif
}


@end