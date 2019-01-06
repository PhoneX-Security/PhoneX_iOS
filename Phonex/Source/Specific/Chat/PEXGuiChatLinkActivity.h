//
// Created by Dusan Klinec on 21.02.16.
// Copyright (c) 2016 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXGuiChatLinkActivity : NSObject
- (void) openUrl: (NSURL *) url forView: (UIView * const) view;
- (void) openUrls: (NSArray<NSURL*>*) urls forView: (UIView * const) view;
- (void) openItems: (NSArray*) items forView: (UIView * const) view;
@end