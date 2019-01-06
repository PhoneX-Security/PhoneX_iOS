//
//  PEXGuiPreviewActivity.m
//  Phonex
//
//  Created by Matej Oravec on 09/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiPreviewActivity.h"

#import "PEXGuiPreviewExecutor.h"
#import "PEXQlItem.h"

#import <QuickLook/QuickLook.h>

@interface PEXGuiPreviewActivity ()

@property (nonatomic) PEXGuiPreviewExecutor * executor;

@end

@implementation PEXGuiPreviewActivity

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
    return PEXStr(@"L_quick_preview");
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"preview"];
}

- (bool) canPerformWithItem: (id) item
{
    const bool result = [PEXGuiPreviewExecutor canPerformWithQlItem:[[PEXQlItem alloc] initWithFileUrl:item]];
    return result;
}

- (void)prepareWithActivityItems:(NSArray *)fileUrls
{
    self.executor = [[PEXGuiPreviewExecutor alloc] initWithListener:self superController:self.superController];

    [self.executor prepareWithActivityItems:
        [PEXGuiPreviewExecutor extractQlItems:fileUrls]];
}

- (void) present
{
    [self.executor present];
}

- (void)previewDidDismiss
{
    [self.delegate previewDidDismiss];
}

@end
