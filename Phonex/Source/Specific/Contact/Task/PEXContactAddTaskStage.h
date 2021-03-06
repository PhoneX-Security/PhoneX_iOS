//
// Created by Dusan Klinec on 06.11.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum PEXContactAddStage : NSInteger PEXContactAddStage;
enum PEXContactAddStage : NSInteger {
    PEX_CONTACT_ADD_STAGE_1,
    PEX_CONTACT_ADD_STAGE_PREPARE=0,
    PEX_CONTACT_ADD_STAGE_CERT_FETCH,
    PEX_CONTACT_ADD_STAGE_CERT_PROCESS,
    PEX_CONTACT_ADD_STAGE_CONTACT_STORE_SOAP,
    PEX_CONTACT_ADD_STAGE_CONTACT_STORE_LOCALLY,
    PEX_CONTACT_ADD_STAGE_ROLLBACK,
};

typedef enum PEXContactAddResultDescription : NSInteger PEXContactAddResultDescription;
enum PEXContactAddResultDescription : NSInteger {
    PEX_CONTACT_ADD_RESULT_ADDED,
    PEX_CONTACT_ADD_RESULT_UNKNOWN_USER,
    PEX_CONTACT_ADD_RESULT_ALREADY_ADDED,
    PEX_CONTACT_ADD_RESULT_ILLEGAL_LOGIN_NAME,
    PEX_CONTACT_ADD_RESULT_NO_NETWORK,
    PEX_CONTACT_ADD_RESULT_CONNECTION_PROBLEM,
    PEX_CONTACT_ADD_RESULT_SERVERSIDE_PROBLEM,
    PEX_CONTACT_ADD_CANCELLED
};
