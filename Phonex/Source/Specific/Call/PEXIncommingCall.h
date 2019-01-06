//
//  PEXIncommingCall.h
//  Phonex
//
//  Created by Matej Oravec on 25/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXCall.h"

@interface PEXIncommingCall : PEXCall

- (id) initWithContact: (const PEXDbContact * const) contact
                pjCall: (PEXPjCall * const) pjCall;

@end
