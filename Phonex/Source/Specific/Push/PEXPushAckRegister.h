//
// Created by Dusan Klinec on 01.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Intended purpose: holds register of the push messages that needs to be acknowledged.
 * Generates ack message and process ack response, marking messages as ACKed according to timestamps. ACKing messages
 * with same and lower timestamp with same action name and optionally action key.
 *
 * If push notification has action key, it has to be acked individually.
 *
 * If newer push message arrives meanwhile, it has bigger timestamp so ack response wont mark it as ACKed, but includes
 * in the next ACK round.
 */
@interface PEXPushAckRegister : NSObject
@end