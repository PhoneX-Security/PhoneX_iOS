//
// Created by Dusan Klinec on 02.11.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXMuteNotificationUpdateExecutor : PEXGuiExecutor
-(void) finishWithSuccess: (BOOL) success completionHandler: (dispatch_block_t) completionHandler;
@end