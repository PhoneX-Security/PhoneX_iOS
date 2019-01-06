//
// Created by Dusan Klinec on 26.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PEXXmppManager;

/**
* Singleton class for handling general XMPP management.
* Holds instance to the primary XMPP manager for currently logged in user.
*
* TODO: refactor for multiuser or move to the application state.
*/
@interface PEXXmppCenter : NSObject
@property(nonatomic) PEXXmppManager * xmppManager;
+ (PEXXmppCenter *)instance;

@end