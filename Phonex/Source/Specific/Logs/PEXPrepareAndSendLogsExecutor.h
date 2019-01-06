//
// Created by Matej Oravec on 02/09/15.
// Copyright (c) 2015 PhoneX. All rights reserved.
//

#import "PEXGuiExecutor.h"


@interface PEXPrepareAndSendLogsExecutor : PEXGuiExecutor

@property (nonatomic) NSString * userMessage;
@property (nonatomic, copy) void (^preparationCompletion)(const bool);

@end