// ZHLLogFormatter.h
// Description：控制日志格式
// Created by CloudChou on 29/10/2017.
// Copyright (c) 2017 Bottle Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLCLogFormatter : NSObject<DDLogFormatter>

@property(nonatomic, assign) BOOL logColor;

@property(nonatomic, copy) NSString *prefix;

- (instancetype)init;

- (instancetype)initWithColorAndPrefix:(BOOL)logColor prefix:(NSString *)prefix;

@end
