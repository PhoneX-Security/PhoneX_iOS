//
// Created by Dusan Klinec on 16.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXSubTaskEvents.h"
#import "PEXSubTask.h"


@implementation PEXSubTaskFinishedEvent {

}
- (NSString *)description {
    NSMutableString *description = [NSMutableString string];
    [description appendFormat:@"self.taskId=%i", self.taskId];
    [description appendFormat:@", self.task=%@", self.task];

    NSMutableString *superDescription = [[super description] mutableCopy];
    NSUInteger length = [superDescription length];

    if (length > 0 && [superDescription characterAtIndex:length - 1] == '>') {
        [superDescription insertString:@", " atIndex:length - 1];
        [superDescription insertString:description atIndex:length + 1];
        return superDescription;
    }
    else {
        return [NSString stringWithFormat:@"<%@: %@>", NSStringFromClass([self class]), description];
    }
}


@end