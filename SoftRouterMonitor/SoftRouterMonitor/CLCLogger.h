//  ZHLLogger.h
//  Description：
//    管理CocoaLumberjack 日志组件的初始化
// Created by CloudChou on 16/11/2017.
// Copyright (c) 2017 Bottle Tech. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CLCLogger : NSObject

+(void) initCocoaLumberJackLog: (NSString *) prefix;

@end