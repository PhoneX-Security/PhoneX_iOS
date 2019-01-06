//
//  PEXPreferenceChangedListener.h
//  Phonex
//
//  Created by Matej Oravec on 20/11/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

@protocol PEXPreferenceChangedListener <NSObject>

- (void) preferenceChangedForKey: (NSString * const) key;

@end
