//
// Created by Matej Oravec on 21/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXLinearDictionary<__covariant SectionType, __covariant ObjectType> : NSObject

- (id) initWithCapacity:(const NSUInteger)capacity;

- (NSMutableArray<ObjectType>  *) getObjects;
- (NSMutableArray<SectionType> *) getSections;

- (NSMutableArray<ObjectType> *) objectsAt: (const NSUInteger) index;
- (SectionType) sectionAt: (const NSUInteger) index;

- (NSUInteger) count;

- (NSIndexPath *)indexPathforObject:(ObjectType)object inSection: (SectionType) section;
- (ObjectType) getObjectAtIndexPath: (NSIndexPath * const) indexPath;

- (NSMutableArray<ObjectType> *) objectsForSectionLast: (SectionType) section;
- (void)addObject: (ObjectType)object forNewSection:(SectionType) section;

- (void) removeAllObjects;


@end