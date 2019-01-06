//
//  PEXLoginTask.h
//  Phonex
//
//  Created by Matej Oravec on 21/09/14.
//  Copyright (c) 2014 Matej Oravec. All rights reserved.
//

#import "PEXTask.h"

#import "PEXLoginTaskResultDescription.h"

#import "PEXLoginTaskEvents.h"
#import "PEXLoginStage.h"
#import "PEXLoginTaskResultDescription.h"
#import "PEXPasswordListener.h"

@class PEXCredentials;

@class PEXLoginTaskResult;
@class PEXGuiController;

@interface PEXLoginTask : PEXTask<PEXTaskListener, PEXPasswordListener>


- (PEXLoginTaskResult *) getResult;


- (id) initWithCredentials: (PEXCredentials * const) credentials
                controller: (PEXGuiController *) controller;

/**
* Parses string encoded JSON aux data to the NSDictionary.
*/
+ (NSDictionary *) parseAuxJson: (NSString *) auxJson pError: (NSError **) pError;

/**
* Processes JSON aux data for application settings set by server.
*/
+ (void) processAppServerSettings: (NSDictionary *) auxJson privData: (PEXUserPrivate *) privData;

/**
 * Processes JSON aux data for account settings set by server.
 */
+ (void) processAccountServerSettings: (NSDictionary *) auxJson privData: (PEXUserPrivate *) privData;

/**
* Processes JSON aux data for application policy set by server.
*/
+ (void) processAppServerPolicy: (NSDictionary *) auxJson privData: (PEXUserPrivate *) privData;
@end
