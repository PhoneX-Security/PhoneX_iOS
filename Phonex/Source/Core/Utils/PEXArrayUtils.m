//
// Created by Matej Oravec on 01/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXArrayUtils.h"


@implementation PEXArrayUtils {

}

+ (void)moveObject:(id) object to: (const NSUInteger) position on: (NSMutableArray * const) marray
{
    const NSUInteger index = [marray indexOfObject:object];
    [self moveFrom:index to:position on:marray];
}

+ (bool)moveFrom:(const NSUInteger) index to: (const NSUInteger) position on:(NSMutableArray * const) marray
{
    NSUInteger newPosition;
    if (![self getMoveNewPosition:index to:position result:&newPosition])
        return false;

    id object = marray[index];
    [marray removeObjectAtIndex:index];
    [marray insertObject:object atIndex:newPosition];

    return true;
}

+ (bool) getMoveNewPosition: (const NSUInteger) from to: (const NSUInteger) to result: (NSUInteger * const) out
{
    const bool toHigher = (from < to);

    // Do nothing if the move makes no changes
    if ((to == from) || (toHigher && (to == from + 1)))
        return false;

    // because the item will be removed and the added again
    *out = (toHigher ? to - 1 : to);

    return true;
}

@end