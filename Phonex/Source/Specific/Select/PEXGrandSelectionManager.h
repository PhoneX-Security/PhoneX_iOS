//
//  PEXSelectionManager.h
//  Phonex
//
//  Created by Matej Oravec on 25/02/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXGuiDialogBinaryListener.h"

@protocol PEXGrandListener

- (void) disintegrated;

@end

@interface PEXGrandSelectionManager : NSObject

@property (nonatomic) NSArray *selectedFileContainers;
@property (nonatomic) NSString * messageText;
@property (nonatomic) NSArray * recipients;

- (void) addListener: (id<PEXGrandListener>) listener;
- (void) removeListener: (id<PEXGrandListener>) listener;
- (void) addController: (UIViewController * const) controller;
- (void) removeController: (UIViewController * const) controller;

- (void) disintegrate;
- (void) finish;


+(void) showNotEnoughFilesToSpend: (const int64_t) available
                           parent: (UIViewController * const) parent;
+(void) showNotEnoughMessagesToSpend: (const int64_t) available
                              parent: (UIViewController * const) parent;

@end

@interface PEXGuiNotEnoughListener : NSObject<PEXGuiDialogBinaryListener>

@property (nonatomic, weak) UIViewController * parent;
@property (nonatomic, weak) UIViewController * dialog;
@property (nonatomic, copy) dispatch_block_t primaryClickBlock;
@property (nonatomic, copy) dispatch_block_t secondaryClickBlock;
@end
