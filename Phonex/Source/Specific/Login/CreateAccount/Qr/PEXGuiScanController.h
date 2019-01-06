//
// Created by Matej Oravec on 05/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <AVFoundation/AVFoundation.h>

@protocol PEXGuiScanControllerDelegate;

@interface PEXGuiScanController : PEXGuiController <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, weak) id<PEXGuiScanControllerDelegate> delegate;

@property (assign, nonatomic) BOOL touchToFocusEnabled;

- (BOOL) isCameraAvailable;
- (void) startScanning;
- (void) stopScanning;
- (void) setTorch:(BOOL) aStatus;

@end

@protocol PEXGuiScanControllerDelegate <NSObject>

@optional

- (void) scanViewController:(PEXGuiScanController *) aCtler didTapToFocusOnPoint:(CGPoint) aPoint;
- (void) scanViewController:(PEXGuiScanController *) aCtler didSuccessfullyScan:(NSString *) aScannedValue;

@end