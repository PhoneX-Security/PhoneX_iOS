//
// Created by Matej Oravec on 31/10/14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum PEXMessageStatusTypeEnum : NSInteger PEXMessageStatusTypeEnum;
enum PEXMessageStatusTypeEnum : NSInteger {
    PEX_MESSAGE_STATUS_TYPE_NORMAL,
    PEX_MESSAGE_STATUS_TYPE_CRITICAL,
    PEX_MESSAGE_STATUS_TYPE_CAUTION
};

@interface PEXMessageStatus : NSObject <NSCoding, NSCopying>

@property (nonatomic) NSString * nameDescription;
@property (nonatomic) PEXMessageStatusTypeEnum type;

- (BOOL)isEqualToStatus:(PEXMessageStatus *)status;
@end