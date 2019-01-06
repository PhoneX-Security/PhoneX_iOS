//
// Created by Dusan Klinec on 03.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertGenKeyGenTaskThread.h"
#import "PEXRSA.h"
#import "PEXGenerator.h"

@interface PEXCertGenKeyGenTaskThread () {}
@property (atomic) BOOL genFinished;
@end

@implementation PEXCertGenKeyGenTaskThread { }
- (instancetype)init {
    self = [super init];
    if (self) {
        self.keyPair = nil;
        self.result = 0;
        self.doneSemaphore = dispatch_semaphore_create(0);
        self.managerDoneSemaphore = nil;
        self.bitSize = PEX_DEFAULT_RSA_BIT_SIZE;
        self.genFinished = NO;
    }

    return self;
}

- (void)main {  @autoreleasepool {
    // Generate a new wrapper.
    RSA * pRsa = NULL;

    // Generate RSA key-pair with 2048 bit size, store it to the state.
    DDLogVerbose(@"<RSA_key_gen %@ size=%lu>", self, (unsigned long)self.bitSize);
    self.result = [PEXGenerator generateRSAKeyPair:self.bitSize andRSA: &pRsa];
    self.keyPair = [[PEXRSA alloc] initWith:pRsa];
    DDLogVerbose(@"</RSA_key_gen %@>", self);
    dispatch_semaphore_signal(self.doneSemaphore);

    // Dispatch semaphore for manager so it can release itself.
    if (self.managerDoneSemaphore != nil){
        dispatch_semaphore_signal(self.managerDoneSemaphore);
        self.managerDoneSemaphore = nil;
    }

    self.genFinished = YES;
}}

- (void)doCancel {

}

- (void)dealloc {
    DDLogVerbose(@"Deallocating cert gen thread");
    if (!self.genFinished && self.managerDoneSemaphore != nil){
        DDLogVerbose(@"Going to signal manager semaphore in dealloc");
        dispatch_semaphore_signal(self.managerDoneSemaphore);
    }
}

@end