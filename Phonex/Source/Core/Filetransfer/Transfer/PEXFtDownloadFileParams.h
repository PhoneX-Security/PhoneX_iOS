//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDhKeyHelper.h"


@interface PEXFtDownloadFileParams : NSObject <NSCoding, NSCopying>
/**
* Nonce2 corresponding to this file download.
*/
@property(nonatomic) NSString * nonce2;

/**
* Notification message ID associated with this file.
*/
@property(nonatomic) NSNumber * msgId;
@property(nonatomic) NSNumber * queueMsgId;

/**
* Destination directory where to extract new files.
*/
@property(nonatomic) NSString * destinationDirectory;

/**
* Whether to create destination directory if does not exist.
*/
@property(nonatomic) BOOL createDestinationDirIfNeeded;

/**
* Specifies policy for newly created files if filename conflict occurs.
*/
@property(nonatomic) PEXFtFilenameConflictCopyAction conflictAction;

/**
* Signalizes delete request / file rejection.
*/
@property(nonatomic) BOOL deleteOnly;

/**
* Delete all artifacts when operation succeeds.
*/
@property(nonatomic) BOOL deleteOnSuccess;

/**
* If YES the download operation downloads the whole file right after
* downloading meta file.
*/
@property(nonatomic) BOOL downloadFullArchiveNow;

/**
* Download full archive if we are on WIFI connection and the file has size under defined
* threshold so it is automatically prepared for the user.
*/
@property(nonatomic) BOOL downloadFullIfOnWifiAndUnderThreshold;

@property(nonatomic) NSUInteger fileTypeIdx;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (BOOL)isEqual:(id)other;
- (BOOL)isEqualToParams:(PEXFtDownloadFileParams *)params;
- (NSUInteger)hash;
- (NSString *)description;

@end