//
// Created by Dusan Klinec on 28.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXPhonexSettings.h"


NSString * CAP_SIP  DEPRECATED_ATTRIBUTE = @"1";
NSString * CAP_XMPP  DEPRECATED_ATTRIBUTE = @"2";
NSString * CAP_XMPP_PRESENCE  DEPRECATED_ATTRIBUTE = @"2.1";
NSString * CAP_XMPP_MESSAGES  DEPRECATED_ATTRIBUTE = @"2.2";
NSString * CAP_PROTOCOL DEPRECATED_ATTRIBUTE = @"3";
// Message protocol v1 - S/MIME
NSString * CAP_PROTOCOL_MESSAGES_1  DEPRECATED_ATTRIBUTE = @"3.1.1";
// Message protocol v2 - based on protocol buffers
NSString * CAP_PROTOCOL_MESSAGES_2 DEPRECATED_ATTRIBUTE = @"3.1.2";
NSString * CAP_PROTOCOL_MESSAGES_2_1 DEPRECATED_ATTRIBUTE = @"3.1.2.1";
NSString * CAP_PROTOCOL_MESSAGES_2_2 = @"3.1.2.2";
NSString * CAP_PROTOCOL_FILETRANSFER DEPRECATED_ATTRIBUTE = @"3.2";
NSString * CAP_PROTOCOL_FILETRANSFER_1 DEPRECATED_ATTRIBUTE = @"3.2.1";
NSString * CAP_PROTOCOL_FILETRANSFER_2  DEPRECATED_ATTRIBUTE = @"3.2.2";
// Supports GCM/APN push notifications even if phonex is not running on the device.
NSString * CAP_PUSH = @"p";

@implementation PEXPhonexSettings {

}

+ (NSSet *)getCapabilities {
    NSSet * caps = [NSSet setWithObjects:CAP_PROTOCOL_MESSAGES_2_2, CAP_PUSH, nil];
    return caps;
}

+ (BOOL)supportMultipleCalls {
    return NO;
}

+ (BOOL)multipleCallsMixingAllowed {
    return NO;
}

+ (BOOL)checkCertificateOnBecomeOnlineEvent {
    return NO;
}

+ (BOOL)takeCellularCallsToBusyState {
    return YES;
}

@end