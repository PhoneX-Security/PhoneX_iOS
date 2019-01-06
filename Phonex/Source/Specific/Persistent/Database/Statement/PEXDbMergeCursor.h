//
// Created by Dusan Klinec on 28.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbCursor.h"


@interface PEXDbMergeCursor : PEXDbCursor
- (instancetype)initWithCursors:(NSArray *)curs;
+ (instancetype)cursorWithCursors:(NSArray *)curs;

+ (PEXDbCursor *) mergeCursors: (PEXDbCursor *) c1 c2: (PEXDbCursor *) c2;
+ (PEXDbCursor *) mergeCursors: (PEXDbCursor *) c1 c2: (PEXDbCursor *) c2 c3: (PEXDbCursor *) c3;
+ (PEXDbCursor *) mergeCursors: (PEXDbCursor *) c1 c2: (PEXDbCursor *) c2 c3: (PEXDbCursor *) c3 c4: (PEXDbCursor *) c4;
+ (PEXDbCursor *) mergeCursors: (PEXDbCursor *) c1 c2: (PEXDbCursor *) c2 c3: (PEXDbCursor *) c3 c4: (PEXDbCursor *) c4 c5: (PEXDbCursor *) c5;
@end