//
// Created by Dusan Klinec on 21.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXPaymentRestoreRecord : NSObject <NSCoding, NSCopying>
@property (nonatomic) NSError * error;
@property (nonatomic) BOOL restoreReceiptOK;
@property (nonatomic) BOOL restoreTransactionOK;
@property (nonatomic) BOOL receiptUploadOK;
@property (nonatomic) BOOL licenseRefreshOK;
@property (nonatomic) BOOL restoreInProgress;
@property (nonatomic) BOOL tooEarly;

@property (nonatomic) NSArray * transactions;
@property (nonatomic) NSMutableSet * transactionIdentifiers;
@property (nonatomic) NSInteger uploadOkTsx;
@property (nonatomic) NSInteger uploadKoTsx;
@property (nonatomic) NSInteger unverifiedTsx;

// Receipt re-upload progress counters.
// Required to know whether all uploads were finished.
@property (nonatomic) NSInteger receiptToReupload;
@property (nonatomic) NSInteger receiptReuploaded;
@property (nonatomic) NSInteger receiptReuploadFailed;

// Unverified transaction handling.
// Required to detect whether all transactions have been processed.
@property (nonatomic) NSInteger transactionsToHandle;
@property (nonatomic) NSInteger transactionsHandled;

-(void) reset;
-(void) incOk;
-(void) incKo;
-(void) incUnverified;
-(void) incTsxHandled;
-(void) addTsxId: (NSString *) transactionIdentifier;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
@end