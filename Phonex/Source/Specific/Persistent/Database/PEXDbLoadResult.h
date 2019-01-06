//
//  DbLoadResult.h
//  Phonex
//
//  Created by Matej Oravec on 20/10/14.
//  Copyright (c) 2014 PhoneX. All rights reserved.
//

#ifndef __Phonex__DbLoadResult__
#define __Phonex__DbLoadResult__

typedef enum PEXDbLoadResult : NSInteger PEXDbLoadResult;
typedef enum PEXDbOpenStatus : NSInteger PEXDbOpenStatus;

enum PEXDbLoadResult : NSInteger {
    PEX_DB_LOAD_OK,
    PEX_DB_LOAD_KEY_PROBLEM,
    PEX_DB_LOAD_RECCREATED,
    PEX_DB_LOAD_FATAL_ERROR,
};

enum PEXDbOpenStatus : NSInteger {
    PEX_DB_OPEN_OK,
    PEX_DB_OPEN_FAIL_CLOSE_PREVIOUS,
    PEX_DB_OPEN_FAIL_NO_FILE,
    PEX_DB_OPEN_FAIL_OPEN_FAILED,
    PEX_DB_OPEN_FAIL_INVALID_KEY,
    PEX_DB_OPEN_FAIL_GENERAL,
};

#endif /* defined(__Phonex__DbLoadResult__) */
