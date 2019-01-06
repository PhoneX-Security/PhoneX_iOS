//
// Created by Dusan Klinec on 19.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PEXDbReceivedFile;
@class PEXInTextData;



@interface PEXMessageModel : NSObject <NSCopying, NSCoding>
@property(nonatomic) PEXDbMessage * message;

/**
 * Attributed string from the message body.
 * By default is initialized from message NSString body.
 * Can be changed if data detector finds something.
 */
@property(nonatomic) NSMutableAttributedString * attributedString;

/**
 * Number of data detected in the message body.
 * Has a valid value only if dataDetectionFinished == YES.
 */
@property(nonatomic) NSUInteger numDataDetectedInBody;

/**
 * Array of preloaded received files.
 */
@property(nonatomic) NSArray<PEXDbReceivedFile *>* receivedFiles;

/**
 * Detected data in the message body.
 */
@property(nonatomic) NSArray<PEXInTextData*>* detectedData;

/**
 * Atomic switches tracking NSDataDetector state on this message.
 */
@property(atomic) BOOL dataDetectionStarted;
@property(atomic) BOOL dataDetectionFinished;

/**
 * Precomputed size of the cell.
 * Optimization to avoid redundant layout computation if no change happen to the cell
 * from the last size recomputation.
 */
@property(atomic) CGSize cellSizeForItem;
@property(atomic) BOOL cellSizeOk;

- (instancetype)initWithMessage:(PEXDbMessage *)message;
+ (instancetype)modelWithMessage:(PEXDbMessage *)message;

- (BOOL)isEqualToModel:(PEXMessageModel *)model;

/**
 * Marks model as dirty. All precomputed values are reset. i.e., computed size.
 * Called when message content changes.
 */
- (void) dirty;

/**
 * Simple delegates to properties of the encapsulated message.
 */
- (NSDate *) date;
- (void) setDate: (NSDate *) date;

- (NSString *) body;
- (void) setBody: (NSString *) body;

- (BOOL) isFile;
- (BOOL) outgoing;
- (NSNumber *) isOutgoing;
- (NSNumber *) id;

@end