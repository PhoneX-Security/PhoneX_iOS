//
// Created by Dusan Klinec on 13.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NSInteger PEXProtocolType;
typedef NSInteger PEXProtocolVersion;

typedef enum PEX_PROTOCOLS {
    PEX_S_MIME = 1,
    PEX_S_MIME_VERSION = 1,

    PEX_STP_SIMPLE = 2,
    PEX_STP_SIMPLE_VERSION_1 = 1,
    PEX_STP_SIMPLE_VERSION_2 = 2,
    PEX_STP_SIMPLE_VERSION_3 = 3,

    PEX_STP_SIMPLE_AUTH = 4,
    PEX_STP_SIMPLE_AUTH_VERSION_1 = 1,
    PEX_STP_SIMPLE_AUTH_VERSION_2 = 2,

    PEX_STP_FTRANSFER = 5,
    PEX_STP_FTRANSFER_VERSION_1 = 1,

    PEX_AMP_TEXT = 1,
    PEX_AMP_TEXT_VERSION_PLAINTEXT = 1,
    PEX_AMP_TEXT_VERSION_AMP_SIMPLE = 2,

    PEX_AMP_NOTIFICATION = 2,
    PEX_AMP_NOTIFICATION_VERSION_GENERAL_MSG_NOTIFICATION = 1,

    // New message queue types for upload and download.
    PEX_AMP_FTRANSFER = 3,
    PEX_AMP_FTRANSFER_DOWNLOAD = 1,
    PEX_AMP_FTRANSFER_UPLOAD   = 2,

    // Notifications that appear / affect chat and need to be in sync with text messages.
    // For the beginning, only virtual application message protocol, to keep backward compatible, converted back to
    // AMP_NOTIFICATION before sending.
    PEX_AMP_NOTIFICATION_CHAT = 4,
    PEX_AMP_NOTIFICATION_CHAT_VERSION_GENERAL_MSG_NOTIFICATION = 1,
} PEX_PROTOCOLS;

@interface PEXProtocols : NSObject
@end