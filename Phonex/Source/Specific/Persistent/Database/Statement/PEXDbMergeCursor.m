//
// Created by Dusan Klinec on 28.12.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbMergeCursor.h"
#import "PEXDbEmptyCursor.h"

// Consistent with PEXDbCursor.
// TODO: Warning! This is not consistent with numbering in Android! Fix it!
#define POSITION_BEFORE_FIRST 0
#define POSITION_FIRST 1
#define POSITION_LAST(count) (count)
#define POSITION_AFTER_LAST(count) ((count) + 1)

@interface PEXDbMergeCursor () {}
@property (nonatomic) NSArray * cursors;
@property (nonatomic) NSArray * counts;
@property (nonatomic) NSArray * partialSums;
@property (nonatomic) BOOL closed;
@property (nonatomic) NSUInteger curCursorIdx;
@property (nonatomic) int curPosition;
@property (nonatomic) int totalCount;
@end


@implementation PEXDbMergeCursor {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.curCursorIdx = 0;
        self.curPosition = POSITION_BEFORE_FIRST;
        self.closed = NO;
        self.totalCount = -1;
        self.cursors = [[NSArray alloc] init];
        self.counts = [[NSArray alloc] init];
    }

    return self;
}

- (instancetype)initWithCursors:(NSArray *)curs {
    self = [super init];
    if (self) {
        self.totalCount = 0;
        self.curCursorIdx = 0;
        NSMutableArray * counts = [[NSMutableArray alloc] init];
        NSMutableArray * partialSums = [[NSMutableArray alloc] init];

        // Take only non-nil cursors.
        NSMutableArray * cursors = [[NSMutableArray alloc] init];
        for(id ccursor in curs){
            if (ccursor == nil || [ccursor isClosed]){
                continue;
            }

            // ParitalSums_i = SUM_{0}^{i-1}, excluding current element.
            [partialSums addObject:@(self.totalCount)];

            int curCount = [ccursor getCount];
            self.totalCount += curCount;

            [cursors addObject:ccursor];
            [counts addObject:@(curCount)];
        }

        self.counts = counts;
        self.closed = NO;
        self.cursors = [cursors copy];
        self.partialSums = [partialSums copy];
        self.curPosition = POSITION_BEFORE_FIRST;
    }

    return self;
}

+ (instancetype)cursorWithCursors:(NSArray *)curs {
    return [[self alloc] initWithCursors:curs];
}

- (void) throwIfClosed {
    if (self.closed) {
        [NSException raise:@"DBException" format:@"Cursor is closed"];
    }
}

- (void) throwIfOutOfBounds: (int) position {
    if (position <= POSITION_BEFORE_FIRST || position >= POSITION_AFTER_LAST(self.totalCount)){
        [NSException raise:@"DBException" format:@"Cursor position is out of bounds"];
    }
}

- (PEXDbCursor *) getCursorFromPosition: (int) pos {
    return self.cursors[[self getCursorIdxFromPosition:pos]];
}

- (NSUInteger) getCursorIdxFromPosition: (int) pos {
    if (pos <= POSITION_BEFORE_FIRST || pos >= POSITION_AFTER_LAST(self.totalCount)) {
        return 0;
    }

    const NSUInteger numCursors = [self.counts count];

    NSUInteger cursorIdx = 0;
    NSInteger partialSum = 0;
    for (; cursorIdx < numCursors; cursorIdx++){
        // Terminate search after partial sum overflows position, count may be zero.
        // This search works with position starting at 0 @ valid record.
        if ((pos - POSITION_FIRST) < partialSum){
            break;
        }

        partialSum += [self.counts[cursorIdx] integerValue];
    }

    return cursorIdx - 1;
}

- (int) getPositionInsideCurrentCursor: (NSUInteger) curCursorIdx curPosition: (int) curPosition {
    NSNumber * partialSum = self.partialSums[curCursorIdx];
    NSInteger partSum = [partialSum integerValue];
    return curPosition - partSum;
}

- (void)close {
    [self throwIfClosed];
    if (self.cursors == nil || [self.cursors count] == 0) {
        return;
    }

    // Close all cursors.
    for (PEXDbCursor * cursor in self.cursors){
        [cursor close];
    }
}

- (int)getColumnCount {
    [self throwIfClosed];
    if (self.cursors == nil || [self.cursors count] == 0) {
        return 0;
    }

    return [self.cursors[self.curCursorIdx] getColumnCount];
}

- (int)getColumnIndex:(NSString *const)columnName {
    [self throwIfClosed];
    if (self.cursors == nil || [self.cursors count] == 0) {
        return 0;
    }

    return [self.cursors[self.curCursorIdx] getColumnIndex:columnName];
}

- (NSString *)getColumnName:(const int)index {
    [self throwIfClosed];
    if (self.cursors == nil || [self.cursors count] == 0) {
        return nil;
    }

    return [self.cursors[self.curCursorIdx] getColumnName:index];
}

- (int)getCount {
    [self throwIfClosed];
    if (self.cursors == nil || [self.cursors count] == 0) {
        return 0;
    }

    return self.totalCount;
}

- (int)getPosition {
    return self.curPosition;
}

- (bool)move:(const int)offset {
    return [self moveToPosition:self.curPosition + offset];
}

- (bool)moveToPrevious {
    return [self move:-1];
}

- (bool)moveToNext {
    return [self move:1];
}

- (bool)moveToPosition:(const int)position {
    [self throwIfClosed];

    // Moving to absolute position in current cursor.
    if (position <= POSITION_BEFORE_FIRST){
        self.curPosition = -1;
        return false;
    }

    if (position >= POSITION_AFTER_LAST(self.totalCount)){
        self.curPosition = POSITION_AFTER_LAST(self.totalCount);
        return false;
    }

    self.curPosition = position;
    self.curCursorIdx = [self getCursorIdxFromPosition:self.curPosition];

    // Move has to be called also on underlying cursor.
    if (self.curCursorIdx < [self.cursors count]) {
        int intCursorPos = [self getPositionInsideCurrentCursor:self.curCursorIdx curPosition:self.curPosition];
        return [self.cursors[self.curCursorIdx] moveToPosition: intCursorPos];
    } else {
        int lastCursorIdx = [self.cursors count] - 1;
        int intCursorPos = [self getPositionInsideCurrentCursor:lastCursorIdx curPosition:self.totalCount];
        return [self.cursors[lastCursorIdx] moveToPosition:intCursorPos];
    }
}

- (bool)moveToLast {
    return [self moveToPosition:self.totalCount-1];
}

- (bool)moveToFirst {
    return [self moveToPosition:0];
}

- (bool)moveBeforeFirst {
    return [self moveToPosition:-1];
}

- (bool)isAfterLast {
    return self.curPosition >= POSITION_AFTER_LAST(self.totalCount);
}

- (bool)isBeforeFirst {
    return self.curPosition <= POSITION_BEFORE_FIRST;
}

- (bool)isFirst {
    return self.curPosition == POSITION_FIRST;
}

- (bool)isLast {
    return self.curPosition == POSITION_LAST(self.totalCount);
}

- (bool)isClosed {
    return self.closed;
}

- (NSData *)getBlob:(const int)position {
    [self throwIfClosed];
    [self throwIfOutOfBounds:self.curPosition];
    return [self.cursors[self.curCursorIdx] getBlob:position];
}

- (NSNumber *)getDouble:(const int)position {
    [self throwIfClosed];
    [self throwIfOutOfBounds:self.curPosition];
    return [self.cursors[self.curCursorIdx] getDouble:position];
}

- (NSNumber *)getInt:(const int)position {
    [self throwIfClosed];
    [self throwIfOutOfBounds:self.curPosition];
    return [self.cursors[self.curCursorIdx] getInt:position];
}

- (NSNumber *)getInt64:(const int)position {
    [self throwIfClosed];
    [self throwIfOutOfBounds:self.curPosition];
    return [self.cursors[self.curCursorIdx] getInt64:position];
}

- (NSString *)getString:(const int)position {
    [self throwIfClosed];
    [self throwIfOutOfBounds:self.curPosition];
    return [self.cursors[self.curCursorIdx] getString:position];
}

- (int)getType:(const int)position {
    [self throwIfClosed];
    [self throwIfOutOfBounds:self.curPosition];
    return [[self getCursorFromPosition:self.curPosition] getType:position];
}

+ (PEXDbCursor *)mergeCursors:(PEXDbCursor *)c1 c2:(PEXDbCursor *)c2 {
    return [self mergeCursors:c1 c2:c2 c3:nil c4:nil c5:nil];
}

+ (PEXDbCursor *)mergeCursors:(PEXDbCursor *)c1 c2:(PEXDbCursor *)c2 c3:(PEXDbCursor *)c3 {
    return [self mergeCursors:c1 c2:c2 c3:c3 c4:nil c5:nil];
}

+ (PEXDbCursor *)mergeCursors:(PEXDbCursor *)c1 c2:(PEXDbCursor *)c2 c3:(PEXDbCursor *)c3 c4:(PEXDbCursor *)c4 {
    return [self mergeCursors:c1 c2:c2 c3:c3 c4:c4 c5:nil];
}

+ (PEXDbCursor *)mergeCursors:(PEXDbCursor *)c1 c2:(PEXDbCursor *)c2 c3:(PEXDbCursor *)c3 c4:(PEXDbCursor *)c4 c5:(PEXDbCursor *)c5 {
    NSMutableArray * cursors = [NSMutableArray arrayWithCapacity:5];
    if (c1 != nil) [cursors addObject:c1];
    if (c2 != nil) [cursors addObject:c2];
    if (c3 != nil) [cursors addObject:c3];
    if (c4 != nil) [cursors addObject:c4];
    if (c5 != nil) [cursors addObject:c5];
    if ([cursors count] == 0){
        return [PEXDbEmptyCursor instance];
    }

    return [PEXDbMergeCursor cursorWithCursors:cursors];
}

@end