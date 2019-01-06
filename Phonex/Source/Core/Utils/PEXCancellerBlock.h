//
// Created by Dusan Klinec on 21.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXCanceller.h"

/**
* Cancel block. Returns TRUE if current operation should be cancelled.
*/
typedef BOOL (^CancelBlock)();

@interface PEXCancellerBlock : NSObject<PEXCanceller>
@property(nonatomic, copy) CancelBlock isCancelledBlock;
- (instancetype)initWithIsCancelledBlock:(CancelBlock) isCancelledBlock;
+ (instancetype)blockWithIsCancelledBlock:(CancelBlock) isCancelledBlock;
@end