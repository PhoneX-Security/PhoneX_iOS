//
// Created by Dusan Klinec on 12.06.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTaskListener.h"

@class hr_trialEventSaveResponse;
@class PEXSOAPResult;


@interface PEXTrialEventTask : NSObject<PEXTaskListener>

/**
* SOAP request for storing event type to the server.
*
* @param privData  private data object to use for SOAP HTTPS connection initialization & server authentication.
* @param eventType integer identification of an event that should be stored on the server. Timestamp of the event is provided by server.
* @param cancelBlock cancel block object to interrupt synchronous request. Optional, may be nil.
* @param res SOAP result object, contains information about error.
* @return event save response. If error / cancellation occurs, response is nil.
*/
-(hr_trialEventSaveResponse *) requestUserInfo: (PEXUserPrivate *) privData eventType: (int) eventType cancelBlock: (cancel_block) cancelBlock res: (PEXSOAPResult **) res;

@end