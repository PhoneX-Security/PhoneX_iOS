//
// Created by Dusan Klinec on 24.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXDbContentValues.h"
#import "PEXDbCursor.h"

@protocol PEXDbModel <NSObject>
-(PEXDbContentValues *) getDbContentValues;
-(void) createFromCursor: (PEXDbCursor *) c;
@end
