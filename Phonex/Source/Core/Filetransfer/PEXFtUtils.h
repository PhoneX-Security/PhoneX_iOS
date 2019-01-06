//
// Created by Dusan Klinec on 24.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXPbGeneralMsgNotification;
@class PEXDbContentProvider;

@interface PEXFtUtils : NSObject

/**
* generate Base64 encoded serialized content of protobuf file notification message
* it notifies that there is file ready for him/her to receive
* @param nonceId - nonce2 from GetKey protocol, uniquely identifies file
* @param filename
* @param sipMessageNonce - unique nonce of SipMessage (as file notification is also associated with some SipMessage)
* @return
*/
+(PEXPbGeneralMsgNotification *) createFileNotification: (NSString *) nonceId filename: (NSString *) filename msgNonce: (UInt32) sipMessageNonce;

/**
* set message property FIELD_TYPE to MESSAGE_TYPE_FILE_REJECTED
* @param id message ID
* @param ctx
*/
+(void) setMessageToRejected: (int64_t) msgId cr: (PEXDbContentProvider *) cr;

@end