//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#define PEX_DEFAULT_RSA_BIT_SIZE 2048

@class PEXRSA;

/**
* Background thread for actual RSA key gen.
*/
@interface PEXCertGenKeyGenTaskThread : NSThread {}
@property (atomic) PEXRSA * keyPair;
@property (atomic) int result;
@property (nonatomic) dispatch_semaphore_t doneSemaphore;
@property (nonatomic) NSUInteger bitSize;

/**
* Extra semaphore to signal when finished - from generator manager.
*/
@property (nonatomic, weak) dispatch_semaphore_t managerDoneSemaphore;

/**
* Signals to cancel.
* NOT IMPLEMENTED YET.
*/
-(void) doCancel;
@end