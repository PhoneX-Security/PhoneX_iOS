#import "PEXUploader.h"

@class PEXMultipartUploadStream;

@interface PEXUploader ()

@property(nonatomic) NSString * boundary;
@property(nonatomic) NSMutableData * responseData;

@property(nonatomic) BOOL endSignalized;
@property(nonatomic) dispatch_semaphore_t endSemaphore;

@property(nonatomic, assign) int64_t uploadLength;
@property(nonatomic, assign) NSInteger statusCode;
@property(nonatomic, assign) int64_t expectedContentLength;
@property(nonatomic, assign) int64_t totalBytesSent;
@property(nonatomic) PEXPbRESTUploadPost * restResponse;

@property(nonatomic) PEXMultipartUploadStream * uploadStream;

- (void) checkIfCancelled;
- (BOOL) isCancelled;
- (void) processFinished;

@end