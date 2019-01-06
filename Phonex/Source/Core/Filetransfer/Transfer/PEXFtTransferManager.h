//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXFtProgress.h"

@protocol PEXCanceller;
@class PEXFtDownloadFileParams;
@class PEXFtDownloadEntry;
@class PEXFtUploadParams;
@class PEXFtUploadEntry;
@class PEXDbContentProvider;


extern NSString * const PEX_ACTION_FTRANSFET_UPDATE_PROGRESS_DB;
extern NSString * const PEX_EXTRA_FTRANSFET_UPDATE_PROGRESS_DB;

extern NSString * const PEX_ACTION_FTRANSFET_DO_CANCEL_TRANSFER;
extern NSString * const PEX_EXTRA_FTRANSFET_DO_CANCEL_TRANSFER_ID;

@interface PEXFtTransferManager : NSObject
@property (nonatomic, weak) PEXUserPrivate * privData;
@property (nonatomic) id<PEXCanceller> canceller;

/**
* Whether to write error codes to the SIP message
*/
@property(nonatomic) BOOL writeErrorToMessage;

/**
* Delete files from server (e.g., after successful download) ?
*/
@property(nonatomic) BOOL deleteFromServer;

-(void) doCancel;

+ (PEXFtTransferManager *)instance;
- (void)onAccountLoggedIn;
- (void)onConnectivityChangeNotification:(NSNotification *)notification;
- (void)onCertUpdated:(NSNotification *)notification;
- (void)onUserUpdated:(NSNotification *)notification;
- (void)onAppState:(NSNotification *)notification;
-(void) doRegister;
-(void) doUnregister;
-(void) quit;

/**
* Dispatches download transfer to message queue.
*/
+(void) dispatchDownloadTransfer: (PEXDbMessage *) msg accept: (NSNumber *) accept;

/**
* Add new file to download queue.
*
* @param params
*/
-(void) enqueueFile2Download: (PEXFtDownloadFileParams *) params;

/**
* Add new file to download queue.
*
* @param params
* @param storeResult
* @param deleteOnly
*/
-(void) enqueueFile2Download: (PEXFtDownloadFileParams *) params storeResult: (BOOL) storeResult deleteOnly: (BOOL) deleteOnly;

/**
* Standard API for starting meta download for a given file. Method often called in background
* so there are thumbnails and meta information to display for user so he can decide whether to accept or reject file transfer.
* By calling this method request for meta file download is enqueued.
*/
-(void) enqueueDownload: (NSString *) nonce2 msgId: (NSNumber *) msgId;
+ (PEXFtDownloadFileParams * ) getDefaultDownloadParams: (NSString *) nonce2 msgId:(NSNumber *)msgId;

/**
* Standard API for accepting file being downloaded.
* By calling this method request for full file download is enqueued.
*/
-(void) enqueueDownloadAccept: (NSString *) nonce2 msgId: (NSNumber *) msgId;

/**
* Standard API for rejecting file transfer.
* By calling this method request for file delete is enqueued.
*/
-(void) enqueueDownloadReject: (NSString *) nonce2 msgId: (NSNumber *) msgId;

/**
* Add new file to upload queue.
*
* @param params
*/
-(void) enqueueFile2Upload: (PEXFtUploadParams *) params;

/**
* Deletes all file transfer records associated with given message id.
*/
+ (void)deleteTransferRecords: (PEXDbContentProvider *) cr withMessageId: (int64_t)dbMessageId;

/**
* Deletes all transfer records regarding this user. Used in user delete procedure.
*/
+ (void)deleteTransferRecords: (PEXDbContentProvider *) cr forUser: (NSString *)username;
+ (void)deleteTransferRecords:(PEXDbContentProvider *)cr forMessageIds:(NSArray * const)ids;

-(BOOL) isDownloadQueueEmpty;
-(PEXFtDownloadEntry *) peekDownloadQueue;
-(PEXFtDownloadEntry *) pollDownloadQueue;
- (BOOL)isUploadQueueEmpty;
- (PEXFtUploadEntry *)peekUploadQueue;
- (PEXFtUploadEntry *)pollUploadQueue;

-(void) cancelTransfer: (PEXDbMessage *) message;

/**
* Publishes error occurred in transfer.
* @param msgid
* @param error
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error isUpload:(BOOL) isUpload;

/**
* Publishes error occurred in transfer.
* @param msgid
* @param error
* @param errCode
* @param errString
*/
-(void) publishError: (int64_t) msgid error: (PEXFtError) error errCode: (NSNumber *) errCode errString: (NSString *) errString nsError: (NSError *) nserror isUpload:(BOOL) isUpload;

/**
* Publishes progress by specifying progress details.
* @param msgid
* @param title
* @param progress
*/
-(void) publishProgress: (int64_t) msgid title: (PEXFtProgressEnum) title progress: (int) progress;

/**
* Publishes DONE progress event.
* @param msgid
*/
-(void) publishDone: (int64_t) msgid;

/**
* Method for publishing a download progress.
* If the progress is changed, it is broadcasted by intent.
* @param progress
*/
-(void) publishProgress: (PEXFtProgress *) progress;

@end
