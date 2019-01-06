//
// Created by Dusan Klinec on 15.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PEXTransferProgressProtocol <NSObject>

// partial progress (1 file) and total progress (overall).
-(void) updateTxProgress: (NSNumber *) partial total: (double) total;
@end