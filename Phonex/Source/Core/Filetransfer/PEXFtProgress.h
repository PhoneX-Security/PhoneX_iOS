//
// Created by Dusan Klinec on 06.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
* Possible error states that can occur in a file-transfer process.
* @author ph4r05
*/
typedef enum  {
    PEX_FT_ERROR_NONE=0,				  // No error
    PEX_FT_ERROR_GENERIC_ERROR,			  // Generic error, error condition not covered by other cases.
    PEX_FT_ERROR_BAD_RESPONSE, 			  // Bad response from SOAP server.
    PEX_FT_ERROR_CERTIFICATE_MISSING, 	  // A needed certificate is missing / was not found.
    PEX_FT_ERROR_SECURITY_ERROR, 		  // Critical security error in a protocol (i.e., signature mismatch).
    PEX_FT_ERROR_DHKEY_MISSING,			  // A specified DH key was not found (i.e., in database, on server).
    PEX_FT_ERROR_DOWN_NO_SUCH_FILE_FOR_NONCE, // A file for a given nonce does not exist.
    PEX_FT_ERROR_DOWN_DOWNLOAD_ERROR, 	  // Unspecified error in downloading process (i.e., connection was lost).
    PEX_FT_ERROR_DOWN_DECRYPTION_ERROR,	  // Unspecified error during decryption, file may be malformed.
    PEX_FT_ERROR_UPD_UPLOAD_ERROR, 		  // Unspecified error in uploading process (i.e., connection was lost).
    PEX_FT_ERROR_UPD_ENCRYPTION_ERROR,	  // Unspecified error during encryption.
    PEX_FT_ERROR_UPD_NO_AVAILABLE_DHKEYS, // Destination user has no available DH keys.
    PEX_FT_ERROR_UPD_QUOTA_EXCEEDED,      // Destination user has full mailbox.
    PEX_FT_ERROR_UPD_FILE_TOO_BIG,		  // Uploaded file is too big to be uploaded.
    PEX_FT_ERROR_CANCELLED,				  // Operation was cancelled (e.g., connection).
    PEX_FT_ERROR_TIMEOUT,				  // Operation timed out (e.g., connection).
} PEXFtError;

typedef enum {
    PEX_FT_PROGRESS_CANCELLED=0,            // Operation was cancelled.
    PEX_FT_PROGRESS_ERROR,                  // Operation finished with error.
    PEX_FT_PROGRESS_DONE,                   // Process finished.
    PEX_FT_PROGRESS_IN_QUEUE,               // Request is enqueued and waiting to be processed.
    PEX_FT_PROGRESS_INITIALIZATION,         // Process has started.
    PEX_FT_PROGRESS_COMPUTING_ENC_KEYS,     // Computing crypto keys, DH exchange.

    // Download specific.
    PEX_FT_PROGRESS_RETRIEVING_FILE,        // Download has been started.
    PEX_FT_PROGRESS_DELETING_FROM_SERVER,   // Remote cleanup.
    PEX_FT_PROGRESS_DELETED_FROM_SERVER,    // Remote cleanup finished.
    PEX_FT_PROGRESS_LOADING_INFORMATION,    // Loading information from server.
    PEX_FT_PROGRESS_DOWNLOADING,            // Download process.
    PEX_FT_PROGRESS_LOADING_PRIVATE_FILES,  // Loading private files.
    PEX_FT_PROGRESS_CONNECTING_TO_SERVER,   // Connecting to the server.
    PEX_FT_PROGRESS_FILE_EXTRACTION,        // ZIP extraction started.
    PEX_FT_PROGRESS_DECRYPTING_FILES,       // Decryption process has started.

    // Upload specific.
    PEX_FT_PROGRESS_DOWNLOADING_KEYS,       // DH key download.
    PEX_FT_PROGRESS_KEY_VERIFICATION,       // DH key verification.
    PEX_FT_PROGRESS_UPLOADING,              // Uploading.
    PEX_FT_PROGRESS_ENCRYPTING_FILES,       // DH key verification.
    PEX_FT_PROGRESS_SENDING_NOTIFICATION,   // Sending upload notification.
} PEXFtProgressEnum;

@interface PEXFtProgress : NSObject <NSCoding, NSCopying>

/**
* ID of message display in MessageFragment that should be updated
* each file being uploaded is associated with one such message
*/
@property(nonatomic) int64_t messageId;

/**
* When was this entry updated for the last time.
*/
@property(nonatomic) NSDate * when;

@property(nonatomic) PEXFtProgressEnum progressCode;

/**
* progress message
*/
@property(nonatomic) NSString * title;

/**
* numeric progress,
* from 0-100 determinate progress bar is shown
* otherwise indeterminate progress bar
*/
@property(nonatomic) int progress;

/**
* Specifies if the progress is finished for this entry.
*/
@property(nonatomic) BOOL done;

/**
* Error condition occurred in the progress.
* If error is set, it is terminal state, no further state change
* should be signaled any further.
*/
@property(nonatomic) PEXFtError error;

/**
* Additional information about occurred error.
* Can be used to be more specific in error report - may be used
* to resolve particular issue.
*/
@property(nonatomic) NSNumber * errorCode;

/**
* Additional error NSString *, describing particular error condition.
* In most cases is null/empty. May be used to resolve particular issue.
*/
@property(nonatomic) NSString * errorString;
@property(nonatomic) NSError * nsError;

/**
* True if is upload, else is download.
*/
@property(nonatomic) BOOL upload;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToProgress:(PEXFtProgress *)progress;
- (NSUInteger)hash;
- (NSString *)description;

/**
* Returns whether given error is temporary/may be fixed
* by trying again, from error code.
*
* @param error
* @return
*/
+ (BOOL) isTryAgainError: (PEXFtError) errCode;

- (instancetype)initWithMessageId:(int64_t)messageId progressCode:(PEXFtProgressEnum)progressCode progress:(int)progress;
+ (instancetype)progressWithMessageId:(int64_t)messageId progressCode:(PEXFtProgressEnum)progressCode progress:(int)progress;

@end