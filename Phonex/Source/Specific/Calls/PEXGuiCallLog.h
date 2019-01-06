//
//  PEXGuiCallLog.h
//  Phonex
//
//  Created by Matej Oravec on 21/12/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PEXDbContact.h"
#import "PEXDbCallLog.h"

@interface PEXGuiCallLog : NSObject

@property (nonatomic, assign) bool highlighted;
@property (nonatomic) const PEXDbContact * contact;
@property (nonatomic) PEXDbCallLog * callLog;

@end
