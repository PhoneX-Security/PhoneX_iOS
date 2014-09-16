//
//  PEXTaskFakeEventProgress.h
//  Phonex
//
//  Created by Matej Oravec on 30/08/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PEXTaskEvent.h"

@interface PEXTaskFakeEventProgress : PEXTaskEvent
{
    @private
    float _progress;
}

- (id) initWithProgress: (const float) progress;
- (float) progress;

@end

@interface PEXTaskFakeEventStart : PEXTaskEvent

@end

@interface PEXTaskFakeEventEnd : PEXTaskEvent
{
    @private
    BOOL _success;
}

- (id) initWithSuccess: (const BOOL) success;
- (float) success;

@end
