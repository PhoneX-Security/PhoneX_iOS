//
// Created by Dusan Klinec on 24.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXDbModelBase.h"


@implementation PEXDbModelBase {

}

+ (NSDate *)getDateFromCursor:(PEXDbCursor *)c idx:(int)idx {
    NSNumber * doubleNum = [c getDouble:idx];
    if (doubleNum == nil){
        return nil;
    }

    return [NSDate dateWithTimeIntervalSince1970: [doubleNum doubleValue]];
}

+ (NSNumber *)dateToNumber:(NSDate *)d {
    return @([d timeIntervalSince1970]);
}

+ (NSNumber *)bool2int:(NSNumber *)i {
    return [i boolValue] ? @1 : @0;
}

+ (NSNumber *)int2bool:(NSNumber *)i {
    return [i integerValue] == 1? @YES : @NO;
}

- (void)createFromCursor:(PEXDbCursor *)c {

}

- (PEXDbContentValues *)getDbContentValues {
    DDLogError(@"ERROR! getDbContentValues not implemented for this class %@", self);
    return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [NSException raise:@"NotImplementedException" format:@"Mehod is not implemented in a base class."];
}

- (id)initWithCoder:(NSCoder *)coder {
    return nil;
}

@end