//
// Created by Dusan Klinec on 03.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXDbEmptyCursor.h"


@implementation PEXDbEmptyCursor {

}
+ (PEXDbEmptyCursor *)instance {
    static PEXDbEmptyCursor *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    });

    return _instance;
}

- (void)close {

}

- (int)getColumnCount {
    return 0;
}

- (int)getColumnIndex:(NSString *const)columnName {
    return 0;
}

- (NSString *)getColumnName:(const int)index {
    return nil;
}

- (int)getCount {
    return 0;
}

- (int)getPosition {
    return 0;
}

- (bool)move:(const int)offset {
    return NO;
}

- (bool)moveToPrevious {
    return NO;
}

- (bool)moveToNext {
    return NO;
}

- (bool)moveToPosition:(const int)position {
    return NO;
}

- (bool)moveToLast {
    return NO;
}

- (bool)moveToFirst {
    return NO;
}

- (bool)moveBeforeFirst {
    return NO;
}

- (bool)isAfterLast {
    return YES;
}

- (bool)isBeforeFirst {
    return NO;
}

- (bool)isFirst {
    return NO;
}

- (bool)isLast {
    return NO;
}

- (bool)isClosed {
    return YES;
}

- (NSData *)getBlob:(const int)position {
    return nil;
}

- (NSNumber *)getDouble:(const int)position {
    return nil;
}

- (NSNumber *)getInt:(const int)position {
    return nil;
}

- (NSNumber *)getInt64:(const int)position {
    return nil;
}

- (NSString *)getString:(const int)position {
    return nil;
}

- (int)getType:(const int)position {
    return 0;
}

@end