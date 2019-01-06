//
// Created by Matej Oravec on 09/06/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PEXFileTypeHolder : NSObject

- (id) initWithFilename: (NSString * const) filename;
- (void) releaseResources;


- (bool) isImage;
- (bool) isMovie;
- (bool) isPdf;

@end