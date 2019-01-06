//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "PEXGuiTone.h"
#import "PEXResSounds.h"

@interface PEXGuiTone () {}
@property (nonatomic) double duration;
@end

@implementation PEXGuiTone {

}

- (instancetype)initWithToneName:(NSString *)toneName toneUrl:(NSURL *)toneUrl toneId:(NSString *)toneId {
    self = [super init];
    if (self) {
        self.shouldVibrateOnPlay = NO;
        self.duration = -1.0;
        self.isSystem = NO;
        self.toneName = toneName;
        self.toneUrl = toneUrl;
        self.toneId = toneId;
    }

    return self;
}

- (instancetype)initWithToneName:(NSString *)toneName toneId:(NSString *)toneId {
    self = [super init];
    if (self) {
        self.shouldVibrateOnPlay = NO;
        self.duration = -1.0;
        self.isSystem = NO;
        self.toneName = toneName;
        self.toneUrl = [PEXResSounds getSoundUrl:toneId];
        self.toneId = toneId;
    }

    return self;
}

- (instancetype)initWithToneName:(NSString *)toneName systemCode:(int)systemCode {
    self = [super init];
    if (self) {
        self.shouldVibrateOnPlay = NO;
        self.duration = -1.0;
        self.isSystem = YES;
        self.systemCode = systemCode;
        self.toneName = toneName;
        self.toneId = [NSString stringWithFormat:@"SYSTEM_%d", (int)self.systemCode];
    }

    return self;
}

+ (instancetype)toneWithToneName:(NSString *)toneName systemCode:(int)systemCode {
    return [[self alloc] initWithToneName:(NSString *)toneName systemCode:(int)systemCode];
}


+ (instancetype)toneWithToneName:(NSString *)toneName toneUrl:(NSURL *)toneUrl toneId:(NSString *)toneId {
    return [[self alloc] initWithToneName:toneName toneUrl:toneUrl toneId:toneId];
}

+ (instancetype)toneWithToneName:(NSString *)toneName toneId:(NSString *)toneId {
    return [[self alloc] initWithToneName:toneName toneId:toneId];
}

- (AVAudioPlayer *)play {
    if (self.isSilent){
        return nil;
    }

    if (self.isSystem){
        AudioServicesPlaySystemSound((SystemSoundID)self.systemCode);
        return nil;
    }

    if (self.shouldVibrateOnPlay){
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }

    // Create audio player object and initialize with URL to sound
    NSError * error = nil;
    AVAudioPlayer * audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.toneUrl error:&error];
    if (error != nil){
        DDLogError(@"Error creating audio player: %@", error);
    }


    if (audioPlayer == nil){
        return nil;
    }

    [audioPlayer play];
    return audioPlayer;
}

- (NSString *)getToneResource {
    if (self.isSilent){
        return nil;
    }

    if (self.isSystem){
        return UILocalNotificationDefaultSoundName;
    }

    return self.toneId;
}

- (double)getToneDuration {
    if (self.isSilent || self.toneUrl == nil){
        return -1.0;
    }

    if (self.isSystem){
        return 3.0;
    }

    if (self.duration < 0.0){
        AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:self.toneUrl options:nil];
        if (audioAsset != nil) {
            CMTime audioDuration = audioAsset.duration;
            self.duration = CMTimeGetSeconds(audioDuration);
        }
    }

    return self.duration;
}

- (instancetype)setFIsSilent:(BOOL)isSilent {
    self.isSilent = isSilent;
    return self;
}

- (instancetype)setFShouldVibrate:(BOOL)shouldVibrate {
    self.shouldVibrateOnPlay = shouldVibrate;
    return self;
}

- (instancetype)setFToneName:(NSString *)toneName {
    self.toneName = toneName;
    return self;
}


@end