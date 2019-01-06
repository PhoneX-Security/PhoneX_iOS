//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskEvent.h"

typedef enum PEXContactRemoveResultDescription : NSInteger PEXContactRemoveResultDescription;
enum PEXContactRemoveResultDescription : NSInteger {
    PEX_CONTACT_REMOVE_RESULT_REMOVED,
    PEX_CONTACT_REMOVE_RESULT_UNKNOWN_USER,
    PEX_CONTACT_REMOVE_RESULT_ILLEGAL_LOGIN_NAME,
    PEX_CONTACT_REMOVE_RESULT_NO_NETWORK,
    PEX_CONTACT_REMOVE_RESULT_CONNECTION_PROBLEM,
    PEX_CONTACT_REMOVE_RESULT_SERVERSIDE_PROBLEM,
    PEX_CONTACT_REMOVE_CANCELLED
};

// Result wrapper for contact add result enum. (May be extended in the future).
@interface PEXContactRemoveResult : NSObject
@property(nonatomic) PEXContactRemoveResultDescription resultDescription;
- (instancetype)initWithResultDescription:(PEXContactRemoveResultDescription)desc;
+ (instancetype)resultWithDesc:(PEXContactRemoveResultDescription)desc;
@end

// Task finished event - contains result.
@interface PEXContactRemoveTaskEventEnd : PEXTaskEvent
- (id) initWithResult:(PEXContactRemoveResult * const)result;
- (PEXContactRemoveResult *) getResult;
- (NSString *)description;
@end
