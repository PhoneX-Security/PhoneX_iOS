//
// Created by Matej Oravec on 17/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXPackageItem.h"


@implementation PEXPackageItem {

}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.guiSortOrder = 0;
    }

    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
    [description appendFormat:@"self.anchor=%ld", (long)self.anchor];
    [description appendFormat:@", self.value=%@", self.value];
    [description appendFormat:@", self.permissionServerName=%@", self.permissionServerName];
    [description appendFormat:@", self.validUntil=%@", self.validUntil];
    [description appendFormat:@", self.descriptor=%ld", (long)self.descriptor];
    [description appendFormat:@", self.life=%ld", (long)self.life];
    [description appendFormat:@", self.guiSortOrder=%li", (long)self.guiSortOrder];
    [description appendString:@">"];
    return description;
}


@end