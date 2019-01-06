//
//  PEXRefDictionary.h
//  Phonex
//
//  Created by Matej Oravec on 10/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXRefDictionary : NSObject

- (id) initWithCapacity:(const NSUInteger)capacity;
- (void)setObject: (id)object forKey:(id) key;
- (void)moveForKey:(id) key to: (const NSUInteger) position;
- (void)moveFrom:(const NSUInteger) index to: (const NSUInteger) position;
- (void)removeObjectForKey: (id)key;
- (void) removePairAt: (const NSUInteger) index;
- (id)objectForKey: (id) key;
- (id)keyForObject: (id) object;
- (NSUInteger)indexOfKey: (id) key;

- (id) keyAt: (const NSUInteger) index;
- (void) replaceKey: (id) newKey at: (const NSUInteger) index;
- (id) objectAt: (const NSUInteger) index;

- (NSMutableArray*) getKeys;
- (NSMutableArray*) getObjects;

- (bool) hasKey: (id) key;
- (void) removeAllObjects;

- (NSUInteger) count;

@end
