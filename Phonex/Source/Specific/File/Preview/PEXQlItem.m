//
// Created by Matej Oravec on 17/03/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXQlItem.h"

@interface PEXQlItem ()

@property (nonatomic) NSURL * url;

@end

@implementation PEXQlItem {

}

- (NSURL *) url
{
    return _url;
}
- (id) initWithFileUrl: (NSURL * const) url
{
        self = [super init];

                self.url = url;

                return self;
}


- (NSURL *) previewItemURL
{
        return self.url;
    }

- (NSString *) previewItemTitle
{
        return [[self.url path] lastPathComponent];
    }


@end