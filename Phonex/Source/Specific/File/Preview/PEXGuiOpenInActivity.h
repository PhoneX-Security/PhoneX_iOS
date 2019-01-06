//
//  PEXGuiOpenInActivity.h
//  Phonex
//
//  Created by Matej Oravec on 09/03/15.
//  Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PEXGuiActivity.h"

@class PEXGuiOpenInActivity;

@protocol PEXGuiOpenInActivityDelegate <NSObject>

- (void)openInAppActivityWillPresentDocumentInteractionController:(PEXGuiOpenInActivity*)activity;
- (void)openInAppActivityDidDismissDocumentInteractionController:(PEXGuiOpenInActivity*)activity;
- (void)openInAppActivityDidEndSendingToApplication:(PEXGuiOpenInActivity*)activity;
- (void)openInAppActivityDidSendToApplication:(NSString*)application;

@end

@interface PEXGuiOpenInActivity: PEXGuiActivity <UIDocumentInteractionControllerDelegate>

@property (nonatomic, weak) id<PEXGuiOpenInActivityDelegate> delegate;

- (void)dismissDocumentInteractionControllerAnimated:(BOOL)animated;

@end
