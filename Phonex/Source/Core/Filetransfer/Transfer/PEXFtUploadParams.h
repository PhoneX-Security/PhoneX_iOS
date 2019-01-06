//
// Created by Dusan Klinec on 26.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXFtUploadParams : NSObject <NSCoding, NSCopying>
/**
* Array of files to send, ordered by the preference of appearance.
*/
@property(nonatomic) NSArray * files;

/**
* Destination SIP.
*/
@property(nonatomic) NSString * destinationSip;

/**
* Notification message ID associated with this file.
*/
@property(nonatomic) NSNumber * msgId;
@property(nonatomic) NSNumber * queueMsgId;

@property(nonatomic) NSString * title;
@property(nonatomic) NSString * desc;

- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;
- (NSString *)description;
@end