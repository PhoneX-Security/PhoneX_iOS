//
// Created by Dusan Klinec on 01.07.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXAutoLoginManager;
@interface PEXAutoLoginManager ()

/**
* Has to be called from the main thread.
*/
-(void) doRegister;
-(void) doUnregister;

/**
* Tries to load stored credentials from the KeyChain. If creds are OK, returns YES.
* Synchronous call.
*/
-(BOOL) tryLoadCredentials;

/**
* Tries to open database with passwords loaded from the KeyChain.
* This step involves waiting for a service being ready for operation and deriving encryption keys from the credentials.
* If opening succeeds, private user data is stored in the class.
* [self tryLoadCredentials] has to be called before this call.
*
* Synchronous call. Uses canceller to interrupt keys derivation (may take a while).
*/
-(BOOL) tryOpenDatabase;

/**
* Tries to finish startup procedure after database was successfully opened with stored credentials.
* If service startup was successful, call returns YES and login screen can be successfully skipped.
*
* Synchronous call.
*/
-(BOOL) tryStartServices;

@end