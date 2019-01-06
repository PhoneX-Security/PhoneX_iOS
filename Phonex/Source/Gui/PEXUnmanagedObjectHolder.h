//
//  PEXUnmanagedObjectHolder.h
//  Phonex
//
//  Created by Matej Oravec on 06/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PEXUnmanagedObjectHolder : NSObject

+ (void) initInstance;
+ (PEXUnmanagedObjectHolder *) instance;
+ (void)addActiveObject: (id)object forKey: (id) key;
+ (void)removeActiveObjectForKey: (id)key;
+ (void) clearAll;

@end
