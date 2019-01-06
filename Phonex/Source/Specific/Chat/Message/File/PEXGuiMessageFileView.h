//
//  PEXGuiMessageFileView.h
//  Phonex
//
//  Created by Matej Oravec on 11/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiMessageView.h"

#import "PEXFtTransferManager.h"

@class PEXRefDictionary;

@interface PEXGuiMessageFileView : PEXGuiMessageView

@property (nonatomic, assign, readonly) bool hasThumbs;

- (void)setNamesAndThumbs: (NSArray * const)namesAndThumb
                  message:(const PEXMessageModel * const) message;

+ (bool) messageReadyForThumbnails: (const PEXDbMessage * const) message;

- (void) applyFtProgress:(const PEXFtProgress * const) progress;

- (void) setAcceptBlock: (void (^)(void))block;
- (void) setCancelBlock: (void (^)(void))block;
- (void) setRejectBlock: (void (^)(void))block;

@end
