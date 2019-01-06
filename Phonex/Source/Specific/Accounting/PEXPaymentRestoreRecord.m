//
// Created by Dusan Klinec on 21.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPaymentRestoreRecord.h"


@implementation PEXPaymentRestoreRecord {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self reset];
    }

    return self;
}

-(void) reset {
    self.restoreReceiptOK = NO;
    self.restoreTransactionOK = NO;
    self.receiptUploadOK = NO;
    self.unverifiedTsx = 0;
    self.uploadKoTsx = 0;
    self.uploadOkTsx = 0;
    self.error = nil;
    self.transactions = nil;
    self.restoreInProgress = NO;
    self.tooEarly = NO;
    self.licenseRefreshOK = NO;
    self.transactionIdentifiers = nil;
    self.receiptToReupload = 0;
    self.receiptReuploaded = 0;
    self.receiptReuploadFailed = 0;
    self.transactionsToHandle = 0;
    self.transactionsHandled = 0;
}

-(void) incOk {
    @synchronized (self) {
        self.uploadOkTsx += 1;
    }
}

-(void) incKo {
    @synchronized (self) {
        self.uploadKoTsx += 1;
    }
}

-(void) incUnverified {
    @synchronized (self) {
        self.unverifiedTsx += 1;
    }
}

- (void)incTsxHandled {
    @synchronized (self) {
        self.transactionsHandled += 1;
    }
}

- (void)addTsxId:(NSString *)transactionIdentifier {
    @synchronized (self) {
       if (self.transactionIdentifiers == nil){
           self.transactionIdentifiers = [[NSMutableSet alloc] init];
       }

        [self.transactionIdentifiers addObject:transactionIdentifier];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.error = [coder decodeObjectForKey:@"self.error"];
        self.restoreReceiptOK = [coder decodeBoolForKey:@"self.restoreReceiptOK"];
        self.restoreTransactionOK = [coder decodeBoolForKey:@"self.restoreTransactionOK"];
        self.receiptUploadOK = [coder decodeBoolForKey:@"self.receiptUploadOK"];
        self.licenseRefreshOK = [coder decodeBoolForKey:@"self.licenseRefreshOK"];
        self.restoreInProgress = [coder decodeBoolForKey:@"self.restoreInProgress"];
        self.tooEarly = [coder decodeBoolForKey:@"self.tooEarly"];
        self.transactions = [coder decodeObjectForKey:@"self.transactions"];
        self.transactionIdentifiers = [coder decodeObjectForKey:@"self.transactionIdentifiers"];
        self.uploadOkTsx = [coder decodeIntForKey:@"self.uploadOkTsx"];
        self.uploadKoTsx = [coder decodeIntForKey:@"self.uploadKoTsx"];
        self.unverifiedTsx = [coder decodeIntForKey:@"self.unverifiedTsx"];
        self.receiptToReupload = [coder decodeIntForKey:@"self.receiptToReupload"];
        self.receiptReuploaded = [coder decodeIntForKey:@"self.receiptReuploaded"];
        self.receiptReuploadFailed = [coder decodeIntForKey:@"self.receiptReuploadFailed"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.error forKey:@"self.error"];
    [coder encodeBool:self.restoreReceiptOK forKey:@"self.restoreReceiptOK"];
    [coder encodeBool:self.restoreTransactionOK forKey:@"self.restoreTransactionOK"];
    [coder encodeBool:self.receiptUploadOK forKey:@"self.receiptUploadOK"];
    [coder encodeBool:self.licenseRefreshOK forKey:@"self.licenseRefreshOK"];
    [coder encodeBool:self.restoreInProgress forKey:@"self.restoreInProgress"];
    [coder encodeBool:self.tooEarly forKey:@"self.tooEarly"];
    [coder encodeObject:self.transactions forKey:@"self.transactions"];
    [coder encodeObject:self.transactionIdentifiers forKey:@"self.transactionIdentifiers"];
    [coder encodeInt:self.uploadOkTsx forKey:@"self.uploadOkTsx"];
    [coder encodeInt:self.uploadKoTsx forKey:@"self.uploadKoTsx"];
    [coder encodeInt:self.unverifiedTsx forKey:@"self.unverifiedTsx"];
    [coder encodeInt:self.receiptToReupload forKey:@"self.receiptToReupload"];
    [coder encodeInt:self.receiptReuploaded forKey:@"self.receiptReuploaded"];
    [coder encodeInt:self.receiptReuploadFailed forKey:@"self.receiptReuploadFailed"];
}

- (id)copyWithZone:(NSZone *)zone {
    PEXPaymentRestoreRecord *copy = [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy.error = self.error;
        copy.restoreReceiptOK = self.restoreReceiptOK;
        copy.restoreTransactionOK = self.restoreTransactionOK;
        copy.receiptUploadOK = self.receiptUploadOK;
        copy.licenseRefreshOK = self.licenseRefreshOK;
        copy.restoreInProgress = self.restoreInProgress;
        copy.tooEarly = self.tooEarly;
        copy.transactions = self.transactions;
        copy.transactionIdentifiers = self.transactionIdentifiers;
        copy.uploadOkTsx = self.uploadOkTsx;
        copy.uploadKoTsx = self.uploadKoTsx;
        copy.unverifiedTsx = self.unverifiedTsx;
        copy.receiptToReupload = self.receiptToReupload;
        copy.receiptReuploaded = self.receiptReuploaded;
        copy.receiptReuploadFailed = self.receiptReuploadFailed;
    }

    return copy;
}


@end