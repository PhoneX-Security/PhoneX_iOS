//
// Created by Dusan Klinec on 21.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXTaskFinishedEvent.h"
#import "PEXTaskContainer.h"


@implementation PEXTaskFinishedEvent {

}

- (id)init {
    if (self = [super init]){
        self.finishState = PEX_TASK_FINISHED_NA;
    }

    return self;
}

- (id)initWithState:(PEX_TASK_FINIHED_STATE)state {
    if (self = [self init]){
        self.finishState = state;
    }

    return self;
}

- (BOOL)didFinishOK {
    return self.finishState == PEX_TASK_FINISHED_OK;
}

- (BOOL)didFinishCancelled {
    return self.finishState == PEX_TASK_FINISHED_CANCELLED;
}

- (BOOL)didFinishWithError {
    return self.finishState == PEX_TASK_FINISHED_ERROR;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.finishState=%d", self.finishState];
    [description appendFormat:@", self.finishError=%@", self.finishError];
    [description appendString:@">"];
    return description;
}


@end