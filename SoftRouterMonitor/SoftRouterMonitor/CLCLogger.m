//  ZHLLogger.m
//  Description：
//
// Created by CloudChou on 16/11/2017.
// Copyright (c) 2017 Bottle Tech. All rights reserved.
//
#import "CLCLogFormatter.h"
#import "CLCLogger.h"

@implementation CLCLogger {
}

+ (void)initCocoaLumberJackLog:(NSString *)prefix {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#ifdef USE_CONSOLE_COLOR  // Xcode console 无法显示颜色，AppCode 可以，但这个宏还没定义
    CLCLogFormatter *consoleLogFormatter = [[CLCLogFormatter alloc] initWithColorAndPrefix:TRUE prefix:prefix];
    [DDTTYLogger sharedInstance].logFormatter = consoleLogFormatter;
#endif
    [DDTTYLogger sharedInstance].automaticallyAppendNewlineForCustomFormatters = true;
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    fileLogger.logFormatter = [[CLCLogFormatter alloc] initWithColorAndPrefix:FALSE prefix:prefix];
    [DDLog addLogger:fileLogger];
    DDLogVerbose(@"log init test log level verbose.");
    DDLogDebug(@"log init test log level debug.");
    DDLogInfo(@"log init test log level info.");
    DDLogWarn(@"log init  log level warn.");
    DDLogError(@"log init test log level error.");
}

@end
