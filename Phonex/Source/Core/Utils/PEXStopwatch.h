//
// Created by Dusan Klinec on 26.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#define PEX_STOPWATCH_ENABLED 1


#define PEX_STOPWATCH_NAME_PADDING 20

/**
 * AUX macro to log real source of stopwatch measurement in logs.
 */
#ifdef PEX_STOPWATCH_ENABLED
#define PEX_SW_STARTNAME(x,name) PEXStopwatch * x = [PEXStopwatch buildWithNameAndStart:(name)];
#define PEX_SW_STOPANDLOG(x) [(x) stopAndLog]
#else
#define PEX_SW_STOPANDLOG(x)     do {} while(0)
#define PEX_SW_STARTNAME(x,name) (0)
#endif

/**
* Object for monitoring performance of code.
*/
@interface PEXStopwatch : NSObject
@property (nonatomic, readonly) NSString * name;
@property (nonatomic, readonly) NSTimeInterval totalTime;

- (instancetype)initAndStart;
- (instancetype)initAndStartIf: (BOOL) start;
- (instancetype)initWithName:(NSString *)name;
- (instancetype)initWithNameAndStart:(NSString *)name;

+ (instancetype)buildAndStart;
+ (instancetype)buildWithName:(NSString *)name;
+ (instancetype)buildWithNameAndStart:(NSString *)name;

-(void) start;
-(void) pause;
-(void) resume;
-(NSTimeInterval) current;
-(NSTimeInterval) stop;
-(NSTimeInterval) stopAndLog;
@end