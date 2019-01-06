//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXTaskEvent.h"

typedef enum PEXContactRenameResultDescription : NSInteger PEXContactRenameResultDescription;
enum PEXContactRenameResultDescription : NSInteger {
    PEX_CONTACT_RENAME_RESULT_RENAMED,
    PEX_CONTACT_RENAME_RESULT_UNKNOWN_USER,
    PEX_CONTACT_RENAME_RESULT_ILLEGAL_LOGIN_NAME,
    PEX_CONTACT_RENAME_RESULT_NO_NETWORK,
    PEX_CONTACT_RENAME_RESULT_CONNECTION_PROBLEM,
    PEX_CONTACT_RENAME_RESULT_SERVERSIDE_PROBLEM,
    PEX_CONTACT_RENAME_CANCELLED
};

// Result wrapper for contact add result enum. (May be extended in the future).
@interface PEXContactRenameResult : NSObject
@property(nonatomic) PEXContactRenameResultDescription resultDescription;
- (instancetype)initWithResultDescription:(PEXContactRenameResultDescription)desc;
+ (instancetype)resultWithDesc:(PEXContactRenameResultDescription)desc;
@end

// Task finished event - contains result.
@interface PEXContactRenameTaskEventEnd : PEXTaskEvent
- (id) initWithResult:(PEXContactRenameResult * const)result;
- (PEXContactRenameResult *) getResult;
- (NSString *)description;
@end
