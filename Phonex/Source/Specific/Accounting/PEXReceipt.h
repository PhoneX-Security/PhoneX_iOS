//
// Created by Dusan Klinec on 14.10.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPKCS7;

typedef enum PexReceiptValidationResult : NSInteger {
    PEX_RECEIPT_OK = 0,
    PEX_RECEIPT_NOT_PKCS7,
    PEX_RECEIPT_NOT_SIGNED_PKCS7,
    PEX_RECEIPT_NO_DATA,
    PEX_RECEIPT_VERIFICATION_ERROR,
    PEX_RECEIPT_UNEXPECTED_FORMAT,
    PEX_RECEIPT_INVALID_TARGET
} PexReceiptValidationResult;

@interface PEXReceipt : NSObject
@property (nonatomic) NSURL * receiptUrl;
@property (nonatomic) PEXPKCS7 * receiptPKCS7;
@property (nonatomic) PexReceiptValidationResult validationResult;
@property (nonatomic) BOOL receiptValid;

@property (nonatomic) NSString *bundleIdString;
@property (nonatomic) NSString *bundleVersionString;
@property (nonatomic) NSData *bundleIdData;
@property (nonatomic) NSData *hashData;
@property (nonatomic) NSData *opaqueData;
@property (nonatomic) NSDate *expirationDate;

-(id)initWithUrl:(NSURL *)url;
+(instancetype) receiptWithUrl:(NSURL *) receiptURL;
-(BOOL) verify;


+(NSData* ) getUUIDData;

@end
