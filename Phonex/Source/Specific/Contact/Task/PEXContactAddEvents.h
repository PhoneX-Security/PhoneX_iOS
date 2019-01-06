//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskEvent.h"
#import "PEXContactAddTaskStage.h"

// Progressed event.
@interface PEXContactAddTaskEventProgress : PEXTaskEvent
{
@private
    PEXContactAddStage _stage;
}

/**
* NSProgress link. Progress monitor can use it to display
* accurate progress, if set. If nil it should be ignored and value
* from a previous notification should be kept.
*/
@property (nonatomic) NSProgress * progress;

/**
* If yes, stage value will be ignored.
* Used in a case when only a progress is changed and stage remains the same.
*/
@property (nonatomic) BOOL ignoreStage;

- (id) initWithStage: (const PEXContactAddStage) stage;
- (PEXContactAddStage) stage;
- (NSString *)description;
@end

// Result wrapper for contact add result enum. (May be extended in the future).
@interface PEXContactAddResult : NSObject
@property(nonatomic) PEXContactAddResultDescription resultDescription;
- (instancetype)initWithResultDescription:(PEXContactAddResultDescription)desc;
+ (instancetype)resultWithDesc:(PEXContactAddResultDescription)desc;
@end

// Task finished event - contains result.
@interface PEXContactAddTaskEventEnd : PEXTaskEvent
- (id) initWithResult:(PEXContactAddResult * const)result;
- (PEXContactAddResult *) getResult;
- (NSString *)description;
@end