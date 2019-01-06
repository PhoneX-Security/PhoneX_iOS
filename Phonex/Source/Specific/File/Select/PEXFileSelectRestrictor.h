//
// Created by Matej Oravec on 23/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, PEXSelectionDescriptionStatus) {
    PEX_SELECTION_DESC_STATUS_OK,
    PEX_SELECTION_DESC_STATUS_TOO_MANY_FILES,
    PEX_SELECTION_DESC_STATUS_TOO_FEW_FILES,
    PEX_SELECTION_DESC_STATUS_TOO_LARGE,
    PEX_SELECTION_DESC_STATUS_TOO_SMALL,
    PEX_SELECTION_DESC_STATUS_ERROR
};

@interface PEXSelectionDescriptionInfo : NSObject

@property (nonatomic) NSString * textDescription;
@property (nonatomic) PEXSelectionDescriptionStatus overlaps;

@end

@interface PEXFileSelectRestrictor : NSObject

@property (nonatomic, weak) NSArray * selectedFiles;

- (PEXSelectionDescriptionStatus) overlaps;
- (void) selectionChanged;
- (PEXSelectionDescriptionInfo *) getCurrentStateDescription;

@end