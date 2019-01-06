//
//  PEXGuiLoginExecutorListener.h
//  Phonex
//
//  Created by Matej Oravec on 24/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

@class PEXLoginTaskResult;

@protocol PEXLoginExecutorListener

- (void) loginFinished: (PEXLoginTaskResult * const) result;

@end
