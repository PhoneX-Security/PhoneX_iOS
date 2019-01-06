//
// Created by Dusan Klinec on 15.12.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVAudioPlayer;


@interface PEXGuiTone : NSObject
@property(nonatomic) BOOL isSystem;
@property(nonatomic) BOOL isSilent;
@property(nonatomic) BOOL shouldVibrateOnPlay;
@property(nonatomic) int systemCode;
@property(nonatomic) NSString * toneId;
@property(nonatomic) NSURL * toneUrl;

// Displayed to the user
@property(nonatomic) NSString * toneName;

-(NSString *) getToneResource;
-(double) getToneDuration;

- (instancetype)initWithToneName:(NSString *)toneName toneId:(NSString *)toneId;
+ (instancetype)toneWithToneName:(NSString *)toneName toneId:(NSString *)toneId;
- (instancetype)initWithToneName:(NSString *)toneName toneUrl:(NSURL *)toneUrl toneId:(NSString *)toneId;
+ (instancetype)toneWithToneName:(NSString *)toneName toneUrl:(NSURL *)toneUrl toneId:(NSString *)toneId;
- (instancetype)initWithToneName:(NSString *)toneName systemCode:(int)systemCode;
+ (instancetype)toneWithToneName:(NSString *)toneName systemCode:(int)systemCode;

- (AVAudioPlayer *) play;
- (instancetype) setFShouldVibrate: (BOOL) shouldVibrate;
- (instancetype) setFToneName: (NSString *) toneName;
- (instancetype) setFIsSilent: (BOOL) isSilent;

@end