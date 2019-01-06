//
// Created by Matej Oravec on 16/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <QuickLook/QuickLook.h>

@protocol PEXGuiPreviewDelegate <NSObject>

- (void)previewDidDismiss;

@end

@interface PEXGuiPreviewExecutor : NSObject<QLPreviewControllerDelegate, QLPreviewControllerDataSource>

+ (bool) canPerformWithQlItem: (const id) item;

- (id) initWithListener: (id<PEXGuiPreviewDelegate>) listener superController: (UIViewController * const) superController;

- (void)prepareWithActivityItems:(NSArray *)qlItems;
+ (NSArray *)extractQlItems:(NSArray *)fileUrls;
- (void) present;


@end