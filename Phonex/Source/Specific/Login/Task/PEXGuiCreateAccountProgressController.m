//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiCreateAccountProgressController.h"

#import "PEXGuiProgressController_Protected.h"


@implementation PEXGuiCreateAccountProgressController {

}

- (void) showTaskStarted: (const PEXTaskEvent * const) event
{
    [super showTaskStarted: event];
    [self setTitle:@"Initiating connection"];
}

- (void) showTaskProgressed: (const PEXTaskEvent * const) event
{
    [super showTaskProgressed: event];

    NSString * title = nil;

    if (title)
        [self setTitle:title];
}

@end