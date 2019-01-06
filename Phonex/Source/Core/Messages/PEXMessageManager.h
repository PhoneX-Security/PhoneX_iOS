//
// Created by Dusan Klinec on 18.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXMessageQueueActions.h"

#import "PEXDbContact.h"

@class PEXUserPrivate;
@class PEXToCall;
@class PEXMessageSentDescriptor;
@class PEXFtUploadParams;

FOUNDATION_EXPORT NSString * PEX_ACTION_CHECK_MESSAGE_DB;
FOUNDATION_EXPORT NSString * PEX_ACTION_MESSAGE_RECEIVED;
FOUNDATION_EXPORT NSString * PEX_ACTION_MESSAGE_STORED_FOR_SENDING;

/**
* After user confirms file rejection this intent is broadcasted from confirm dialog.
*/
FOUNDATION_EXPORT NSString * PEX_ACTION_REJECT_FILE_CONFIRMED;
FOUNDATION_EXPORT NSString * PEX_EXTRA_REJECT_FILE_CONFIRMED_MSGID;
FOUNDATION_EXPORT NSString * PEX_ACTION_ACCEPT_FILE_CONFIRMED;
FOUNDATION_EXPORT NSString * PEX_EXTRA_ACCEPT_FILE_CONFIRMED_MSGID;

/**
* High abstract level for message features.
* Handles new message processing.
*/
@interface PEXMessageManager : NSObject <PEXMessageQueueActions>
@property(nonatomic, weak) PEXUserPrivate * privData;
@property(nonatomic) BOOL fetchCertIfMissing;

+ (PEXMessageManager *)instance;
- (instancetype)initWithPrivData:(PEXUserPrivate *)privData;
+ (instancetype)managerWithPrivData:(PEXUserPrivate *)privData;

-(void) triggerCheck;
+(void) triggerCheck;
-(void) dbCheckTask: (BOOL) justStarted;

/**
* Confirms acceptance or rejection of the transfer.
*
* @param msgId
* @param accept
*/
+(void) confirmTransfer:(NSNumber *) msgId accept: (BOOL) accept;

-(void) onAccountLoggedIn;
-(void) onConnectivityChange: (BOOL) recovered;

-(void) doRegister;
-(void) doUnregister;
-(void) quit;

+(NSString *) removeOfflineMessageMetadata: (NSString *) body;
-(BOOL) isCancelled;

/**
* Acknowledged received
* @param statusErrorCode - status code (positive or negative) from PjSip
*/
-(void) acknowledgmentFromPjSip: (NSString*) to returnedFinalMessage: (NSString *) returnedFinalMessage
                       statusOk:(BOOL) statusOk reasonErrorText: (NSString *) reasonErrorText
                statusErrorCode: (int) statusErrorCode;

/**
* File Transfer manager notifies us about the transfer state.
*/
-(void) onTransferFinished: (int64_t) msgId queueMsgId: (int64_t) queueMsgId statusOk: (BOOL) statusOk recoverable: (BOOL) recoverable;

/**
* Event triggered when message was passed to the message stack for sending.
* @param mDesc
*/
-(void) onMessageSent: (PEXMessageSentDescriptor *) mDesc;

/**
* Main method for sending a message from UI to the user. Entry point for new messages.
*/
-(void) sendMessage: (NSString *) from to: (NSString *) to body: (NSString *) body;

/**
* Send files to the remote party.
* Array of files contains PEXFileToSendEntry objects or just NSString with full path or NSURL.
*/
-(void) sendFile: (NSString *) from  to: (NSString *) to title: (NSString *) title desc: (NSString *) desc files: (NSArray *) files;

/**
* Computes message hash from the tet message. Used to identify message in some cases.
*/
+(NSString *) computeMessageHash: (NSString *) message;
+(NSString *) computeMessageHashData: (NSData *) message;

/**
* Keep alive handler.
*/
- (void)keepAlive:(BOOL)async;

+ (void) readAllForSip: (NSString * const) sip;
+ (void) readMessage: (const PEXDbMessage * const) message;

+ (void) removeAllForContact: (const PEXDbContact * const) contact;
+ (void)removeMessageForId: (NSNumber * const) messageId;
+ (void) removeAllOlderThan: (const int64_t)seconds;
+(NSString *) getMsgBodyForFiles: (NSString *) title desc: (NSString *) desc files: (NSArray *) files;
+(void) fileNotificationMessageFnameUpdate: (PEXFtUploadParams *) params newFnames: (NSArray *) files;

@end

@interface PEXMessageSentDescriptor : NSObject <NSCoding, NSCopying> { }
@property(nonatomic) int64_t messageId;
@property(nonatomic) int64_t accountId;
@property(nonatomic) NSString * message;
@property(nonatomic) NSString * msg2store;
@property(nonatomic) NSString * recipient;
@property(nonatomic) BOOL isResend;
@property(nonatomic) PEXToCall * sendResult;
@property(nonatomic) int stackSendStatus;

- (instancetype)initWithMessageId:(int64_t)messageId accountId:(int64_t)accountId
                          message:(NSString *)message msg2store:(NSString *)msg2store
                        recipient:(NSString *)recipient isResend:(BOOL)isResend
                       sendResult:(PEXToCall *)sendResult;

+ (instancetype)descriptorWithMessageId:(int64_t)messageId accountId:(int64_t)accountId
                                message:(NSString *)message msg2store:(NSString *)msg2store
                              recipient:(NSString *)recipient isResend:(BOOL)isResend
                             sendResult:(PEXToCall *)sendResult;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
@end
