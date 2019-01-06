//
// Created by Matej Oravec on 20/05/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXCaptchaLoader.h"
#import "PEXRestRequester_Protected.h"

#import "PEXGuiUtils.h"
#import "PEXSecurityCenter.h"
#import "PEXConnectionUtils.h"

static int S_RESPONSE_OK = 200;
static int S_RESPONSE_ERR_MISSING_FIELDS = 400;
static int S_RESPONSE_ERR_BAD_CAPTCHA = 401;
static int S_RESPONSE_ERR_TRIAL_ALREADY_CREATED = 402;
static int S_RESPONSE_ERR_EXISTING_USERNAME = 404;
static int S_RESPONSE_ERR_USERNAME_BAD_FORMAT = 405;

static NSString * S_REGEX_USERNAME = @"^[a-z0-9_-]{3,18}$";
static NSString * S_CAPTCHA_REQUEST_URL_PATH = @"trial/captcha";

@interface PEXCaptchaLoader ()

@property (nonatomic) UIImage *loadedCaptchaImage;

@property (nonatomic, copy) void (^completion)(UIImage * const);
@property (nonatomic, copy) void (^errorHandler)(void);

@property (nonatomic) NSURLSessionDataTask * requestTask;
@end

@implementation PEXCaptchaLoader {

}

- (bool) loadCaptchaAsyncForHeight: (const CGFloat) heightInPoints
                        completion: (void (^)(UIImage * const))completion
                      errorHandler: (void (^)(void))errorHandler
{
    const int desiredHeightInPixels = (int) [PEXGuiUtils pointsToPixels:heightInPoints];

    NSString * const urlString = [NSString stringWithFormat:
            @"%@?height=%d", [PEXConnectionUtils systemUrlWithPath:S_CAPTCHA_REQUEST_URL_PATH], desiredHeightInPixels];

    WEAKSELF;
    [self defaultTrustInit];
    [self defaultQueueInit];

    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[self defaultConfiguration] delegate:self delegateQueue:self.delegateQueue];

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"PhoneX" forHTTPHeaderField:@"User-Agent"];

    self.requestTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [weakSelf processFinished:data resp:response error:error];
    }];

    bool result = true;
    if (!self.requestTask)
    {
        result = false;
    }
    else
    {
        self.completion = completion;
        self.errorHandler = errorHandler;

        DDLogVerbose(@"Starting captcha task");
        [self.requestTask resume];
    }

    return result;
}

- (NSArray *)satisfactoryCodes
{
    return @[@(200), @(201)];
}

- (void)nilProperties {
    [super nilProperties];
    self.requestTask = nil;
}

- (void) errorOccurred
{
    [super errorOccurred];

    WEAKSELF;
    if (self.errorHandler){
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.errorHandler();
        });
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.loadedCaptchaImage = [UIImage imageWithData:self.receivedData];

    [self nilProperties];

    if (!self.loadedCaptchaImage)
    {
        [self errorOccurred];
    }
    else if (self.completion)
    {
        WEAKSELF;
        if (self.errorHandler){
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.completion(weakSelf.loadedCaptchaImage);
            });
        }
    }
}



@end