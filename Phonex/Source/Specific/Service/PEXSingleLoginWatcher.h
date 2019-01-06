//
// Created by Dusan Klinec on 08.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPushNewCertEvent;

extern NSString * PEX_ACTION_CHECK_SINGLE_LOGIN;
extern NSString * PEX_EXTRA_CHECK_SINGLE_LOGIN;

/**
* Simple PhoneX module taking care only one device is connected to the login name at time.
* There are 2 ways of detection a new device connected with same login name:
*  1. Certificate update for my login name comes, conveying a push message which contains certificate information.
*     Such message leads to certificate check process and if such certificate is updated and varies from the one we use
*     at the moment, logout is performed, with warning dialog.
*
*  2. newCert push message is sent by server. This leads to SOAP call in order to verify validity of current certificate.
*     If current certificate is not valid anymore, logout is performed, with warning dialog.
*
*  Module is weakly coupled to environment, listening to NotificationCenter messages. No direct interaction with other
*  modules is needed.
*/
@interface PEXSingleLoginWatcher : NSObject
-(void) doRegister;
-(void) doUnregister;

@end