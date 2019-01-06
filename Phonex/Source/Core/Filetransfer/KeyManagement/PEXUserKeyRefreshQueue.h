//
// Created by Dusan Klinec on 09.02.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXUserKeyRefreshRecord;


@interface PEXUserKeyRefreshQueue : NSObject
- (instancetype)initWithQueue:(dispatch_queue_t)queue1;
- (instancetype) initWithQueueName: (NSString *) queueName;

-(PEXUserKeyRefreshRecord *) getRecordForUser: (NSString *) user;
-(PEXUserKeyRefreshRecord *) peek;
-(PEXUserKeyRefreshRecord *) poll;

/**
* Updates record defined as parameter. If does not exist in the queue, new is inserted.
*/
-(void) update: (PEXUserKeyRefreshRecord *) record;

@end