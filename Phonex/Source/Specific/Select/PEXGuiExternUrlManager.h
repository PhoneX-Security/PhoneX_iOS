//
//  PEXGuiExternUrlManager.h
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXGrandSelectionManager.h"

@class PEXFileData;

@interface PEXGuiExternUrlManager : NSObject<PEXGrandListener>

+ (PEXGuiExternUrlManager *) instance;

- (bool)sendExternalData: (PEXFileData * const) fileData;

@end
