//
// Created by Dusan Klinec on 09.10.14.
// Copyright (c) 2014 PhoneX. All rights reserved.
//

#import "PEXCertGenTaskEvent.h"


@implementation PEXCertGenTaskEventProgress { }
- (id)init {
    self = [super init];
    if (self){
        self.progress = nil;
        self.stage = PEX_CERT_GEN_STARTED;
    }

    return self;
}

- (id)initWithStage:(const PEXCertGenStage)stage {
    self = [self init];
    if (self){
        self.progress = nil;
        self.stage = stage;
    }

    return self;
}

- (id)initWithStage:(const PEXCertGenStage)stage progress:(NSProgress *)progress {
    self = [self init];
    if (self){
        self.progress = progress;
        self.stage = stage;
    }

    return self;
}

@end



@implementation PEXLoginTaskEventFinished { }
- (id)init {
    self = [super init];
    if (self){
        self.lastProgress = nil;
    }

    return self;
}
@end