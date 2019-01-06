//
// Created by Matej Oravec on 17/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <QuickLook/QuickLook.h>

@interface PEXQlItem : NSObject<QLPreviewItem>

- (id) initWithFileUrl: (NSURL * const) url;

- (NSURL *) url;

@end