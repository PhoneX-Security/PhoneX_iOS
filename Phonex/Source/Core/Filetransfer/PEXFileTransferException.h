//
// Created by Dusan Klinec on 28.01.15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString * PEXFileTransferGenericException;

/**
* Thrown is archive file has unknown/forbidden structure.
* E.g., ZIP file contains folders in protocol version = 1.
*
* @author ph4r05
*
*/
FOUNDATION_EXPORT NSString * PEXFileTransferUnkownArchiveStructureException;
FOUNDATION_EXPORT NSString * PEXFileTransferNotConnectedException;


@interface PEXFileTransferException : NSException
@end