//
// Created by Matej Oravec on 21/07/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXLinearDictionary.h"
#import "PEXDHUserCheckParam.h"

@interface PEXLinearDictionary()

@property (nonatomic) NSMutableArray * sections;
@property (nonatomic) NSMutableArray * objects;

@end

@implementation PEXLinearDictionary {

}

- (id) initWithCapacity:(const NSUInteger)capacity
{
    self = [super init];

    self.sections = [[NSMutableArray alloc] initWithCapacity:capacity];
    self.objects = [[NSMutableArray alloc] initWithCapacity:capacity];

    return self;
}

- (id) init
{
    return [self initWithCapacity:4];
}

- (void) removeAllObjects
{
    [self.sections removeAllObjects];
    [self.objects removeAllObjects];
}

- (NSMutableArray*) getObjects
{
    return self.objects;
}

- (NSMutableArray*) getSections
{
    return self.sections;
}

- (NSMutableArray *) objectsAt: (const NSUInteger) index
{
    return self.objects[index];
}

- (id) sectionAt: (const NSUInteger) index
{
    return self.sections[index];
}

- (NSUInteger) count
{
    return self.sections.count;
}

- (NSIndexPath *)indexPathforObject:(id)object inSection: (id) section
{
    NSIndexPath * result = nil;
    for (NSUInteger sectionIndex = 0; sectionIndex < self.sections.count; ++sectionIndex) {
        const id inSection = self.sections[sectionIndex];
        if (![inSection isEqual:section]){
            continue;
        }

        const NSUInteger itemIndex = [self.objects[sectionIndex] indexOfObject:object];
        if (itemIndex != NSNotFound) {
            result = [NSIndexPath indexPathForItem:itemIndex inSection:sectionIndex];
            break;
        }
    }

    return result;
}

- (id) getObjectAtIndexPath: (NSIndexPath * const) indexPath
{
    return self.objects[indexPath.section][indexPath.item];
}

- (NSMutableArray *) objectsForSectionLast: (id) section
{
    NSMutableArray * result;

    for (NSInteger i = self.sections.count - 1; i > -1; --i)
    {
        id inSection = self.sections[i];

        if ([inSection isEqual:section])
        {
            result = self.objects[i];
            break;
        }
    }

    return result;
}

- (void)addObject: (id)object forNewSection:(id) section;
{
    NSMutableArray * newObjects = [[NSMutableArray alloc] init];
    [newObjects addObject:object];
    [self.sections addObject: section];
    [self.objects addObject: newObjects];
}

- (NSArray *) getSectionsForSection: (id) searchSection
{
    NSMutableArray * const result = [[NSMutableArray alloc] init];

    for (id section in self.sections)
    {
        if ([section isEqual:searchSection])
        {
            [result addObject:section];
        }
    }

    return result;
}

@end