//
//  PEXGuiLoginProgressController.m
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXGuiLoginProgressController.h"
#import "PEXGuiProgressController_Protected.h"

#import "PEXLoginTaskEvents.h"

@interface PEXGuiLoginProgressController ()

@end

@implementation PEXGuiLoginProgressController

- (void) showTaskStarted: (const PEXTaskEvent * const) event
{
    [super showTaskStarted: event];
    [self setTitle:@"Initiating connection"];
    self.screenName = @"LoginProgress";
}

- (void) showTaskProgressed: (const PEXTaskEvent * const) event {
    [super showTaskProgressed:event];
    const PEXLoginTaskEventProgress *const progressEvent =
            ((PEXLoginTaskEventProgress *) event);


    const NSProgress *prog = progressEvent.progress;
    if (prog != nil) {
        [self setProgress:(float const) prog.fractionCompleted];
    }

    // If stage was not set, exit.
    if (progressEvent.ignoreStage) {
        return;
    }

    NSString *title = nil;

    const PEXLoginStage stage = [progressEvent stage];
    switch (stage) {
        case PEX_LOGIN_STAGE_1:
            title = @"Opening the star gate";
            break;
        case PEX_LOGIN_STAGE_CANCELLING:
            title = PEXStr(@"login_msg_cancelling");
            break;
        case PEX_LOGIN_STAGE_AUTH_KEYGEN:
            title = PEXStr(@"login_msg_auth_keygen");
            break;
        case PEX_LOGIN_STAGE_AUTH_SOAP:
            title = PEXStr(@"login_msg_auth_soap");
            break;
        case PEX_LOGIN_STAGE_PCGT_KEYGEN:
            title = PEXStr(@"login_msg_certgen_keygen");
            break;
        case PEX_LOGIN_STAGE_PCGT_OTT:
            title = PEXStr(@"login_msg_certken_ott");
            break;
        case PEX_LOGIN_STAGE_PCGT_SOAP:
            title = PEXStr(@"login_msg_certgen_soap");
            break;
        case PEX_LOGIN_STAGE_PCGT_VERIFY:
            title = PEXStr(@"login_msg_certgen_verify");
            break;
        case PEX_LOGIN_STAGE_PCGT_STORE:
            title = PEXStr(@"login_msg_certgen_store");
            break;
        case PEX_LOGIN_STAGE_PCLT_FETCH_CL:
            title = PEXStr(@"login_msg_cl_fetch");
            break;
        case PEX_LOGIN_STAGE_PCLT_PROCESS_CL:
            title = PEXStr(@"login_msg_cl_process");
            break;
        case PEX_LOGIN_STAGE_PCLT_CERT_REFRESH:
            title = PEXStr(@"login_msg_cl_cert_fetch");
            break;
        case PEX_LOGIN_STAGE_PCLT_CERT_PROCESS:
            title = PEXStr(@"login_msg_cl_cert_process");
            break;
        case PEX_LOGIN_STAGE_PCLT_STORE:
            title = PEXStr(@"login_msg_cl_store");
            break;
        case PEX_LOGIN_STAGE_CHANGEPASS_OTT:
            title = PEXStr(@"login_msg_pass_ott");
            break;
        case PEX_LOGIN_STAGE_CHANGEPASS_SOAP:
            title = PEXStr(@"login_msg_pass_soap");
            break;
        case PEX_LOGIN_STAGE_CHANGEPASS_KEYGEN:
            title = PEXStr(@"login_msg_pass_keygen");
            break;
        case PEX_LOGIN_STAGE_CHANGEPASS_REKEY:
            title = PEXStr(@"login_msg_pass_rekey");
            break;
        default:
            break;
    }

    if (title)
        [self setTitle:title];
}

@end
