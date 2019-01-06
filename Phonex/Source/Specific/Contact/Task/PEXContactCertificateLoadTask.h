//
// Created by Dusan Klinec on 29.06.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"

@interface PEXCertDetails : NSObject
@property(nonatomic) NSInteger certStatus; // refer to CERTIFICATE_STATUS_*
@property(nonatomic) NSDate * dateCreated;
@property(nonatomic) NSDate * dateLastRefresh;
@property(nonatomic) NSString * certHash;
@property(nonatomic) NSDate * notBefore;
@property(nonatomic) NSDate * notAfter;
@property(nonatomic) NSString * certCN;
@end

@interface PEXContactCertificateLoadTask : PEXTask
// Input for the task.
@property(nonatomic) NSString * userName;

// Result of the task
@property(nonatomic) PEXCertDetails * certDetails;
@end