//
// Created by Matej Oravec on 05/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiScanController.h"
#import "PEXGuiController_Protected.h"

@interface PEXGuiScanController ()

@property (strong, nonatomic) AVCaptureDevice* device;
@property (strong, nonatomic) AVCaptureDeviceInput* input;
@property (strong, nonatomic) AVCaptureMetadataOutput* output;
@property (strong, nonatomic) AVCaptureSession* session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer* preview;

@end

@implementation PEXGuiScanController

- (void)initState
{
    [super initState];
    self.screenName = @"Scan";


    if ([self isCameraAvailable])
    {
        [self setupScanner];
        [self startScanning];
    }
    else
    {
        [self setupNoCameraView];
    }
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)evt
{
    if (self.touchToFocusEnabled)
    {
        UITouch * touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self.mainView];
        [self focus:pt];
    }
}

#pragma mark -
#pragma mark NoCamAvailable

- (void) setupNoCameraView;
{
    UILabel *labelNoCam = [[UILabel alloc] init];
    labelNoCam.text = @"No Camera available";
    labelNoCam.textColor = [UIColor blackColor];
    [self.mainView addSubview:labelNoCam];
    [labelNoCam sizeToFit];
    labelNoCam.center = self.mainView.center;
}
/*
- (NSUInteger)supportedInterfaceOrientations;
{
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate;
{
    return (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]));
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation;
{
    if([[UIDevice currentDevice] orientation] == UIDeviceOrientationLandscapeLeft) {
        AVCaptureConnection *con = self.preview.connection;
        con.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
    } else {
        AVCaptureConnection *con = self.preview.connection;
        con.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    }
}
*/
#pragma mark -
#pragma mark AVFoundationSetup

- (void) setupScanner;
{
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    self.session = [[AVCaptureSession alloc] init];

    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
    [self.session addInput:self.input];

    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.session addOutput:self.output];

    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("captureQueue", NULL);
    [self.output setMetadataObjectsDelegate:self queue:dispatchQueue];
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];

    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = CGRectMake(0, 0, self.mainView.frame.size.width, self.mainView.frame.size.height);
    //self.preview.connection = AVCaptureVideoOrientationLandscapeLeft;

    [self.mainView.layer insertSublayer:self.preview atIndex:0];
}

#pragma mark -
#pragma mark Helper Methods

- (BOOL) isCameraAvailable;
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    return [videoDevices count] > 0;
}

- (void)startScanning;
{
    [self.session startRunning];

}

- (void) stopScanning;
{
    [self.session stopRunning];
}

- (void) setTorch:(BOOL) aStatus;
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if ( [device hasTorch] ) {
        if ( aStatus ) {
            [device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
        }
    }
    [device unlockForConfiguration];
}

- (void) focus:(CGPoint) aPoint;
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if([device isFocusPointOfInterestSupported] &&
            [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        double screenWidth = screenRect.size.width;
        double screenHeight = screenRect.size.height;
        double focus_x = aPoint.x/screenWidth;
        double focus_y = aPoint.y/screenHeight;
        if([device lockForConfiguration:nil]) {
            if([self.delegate respondsToSelector:@selector(scanViewController:didTapToFocusOnPoint:)]) {
                [self.delegate scanViewController:self didTapToFocusOnPoint:aPoint];
            }
            [device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                [device setExposureMode:AVCaptureExposureModeAutoExpose];
            }
            [device unlockForConfiguration];
        }
    }
}

#pragma mark -
#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    for(AVMetadataObject *current in metadataObjects) {
        if([current isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
            if([self.delegate respondsToSelector:@selector(scanViewController:didSuccessfullyScan:)]) {
                NSString *scannedValue = [((AVMetadataMachineReadableCodeObject *) current) stringValue];
                [self.delegate scanViewController:self didSuccessfullyScan:scannedValue];
            }
        }
    }
}

@end