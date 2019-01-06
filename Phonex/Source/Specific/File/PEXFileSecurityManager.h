//
// Created by Dusan Klinec on 12.04.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXRegisterable.h"
#import "PEXServiceModuleProtocol.h"

FOUNDATION_EXPORT NSString *PEX_FILE_PROTECTION_SETTING_CHANGED;
@interface PEXFileSecurityManager : NSObject <PEXServiceModuleProtocol>

/**
 * Increase settings version.
 */
-(void) incSettingsVer;
- (void)updatePrivData:(PEXUserPrivate *)privData;
@end