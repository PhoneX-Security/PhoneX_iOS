//
//  PEXLoginTaskEvents.h
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#ifndef Phonex_PEXLoginTaskEvents_h
#define Phonex_PEXLoginTaskEvents_h

@class PEXLoginTaskResult;

#import "PEXTaskEvent.h"

#import "PEXLoginStage.h"
#import "PEXLoginTaskResultDescription.h"

@interface PEXLoginTaskEventProgress : PEXTaskEvent
{
@private
    PEXLoginStage _stage;
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

- (id) initWithStage: (const PEXLoginStage) stage;
- (PEXLoginStage) stage;
- (NSString *)description;
@end

@interface PEXLoginTaskEventEnd : PEXTaskEvent

- (id) initWithResult:(PEXLoginTaskResult * const )result;
- (PEXLoginTaskResult *) getResult;

- (NSString *)description;
@end

#endif
