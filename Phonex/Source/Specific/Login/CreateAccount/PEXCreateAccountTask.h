//
// Created by Matej Oravec on 02/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PEXTask.h"

@class PEXCreateAccountHolder;

typedef enum PEXCreateAccountResult {

    PEX_CREATE_ACCOUNT_SUCCESSFUL_RESPONSE,             // JSON response retrieved successfully
    PEX_CREATE_ACCOUNT_CONNECTION_ERROR,    // error at creating connection
    PEX_CREATE_ACCOUNT_RESPONSE_DATA_ERROR, // response data cloud not be processed successfuly
    PEX_CREATE_ACCOUNT_REQUEST_DATA_ERROR,  // data for request could not be created
    PEX_CREATE_ACCOUNT_REQUEST_ERROR       // http response code error

} PEXCreateAccountResult;

@interface PEXCreateAccountTask : PEXTask

@property (nonatomic) PEXCreateAccountHolder * createAccountInfo;

@property (nonatomic, assign) PEXCreateAccountResult result;
@property (nonatomic, readonly) NSDictionary * jsonResult;
@property (nonatomic, readonly, assign) int httpResponseCode;

@end