//
// Created by CloudChou on 29/10/2017.
// Copyright (c) 2017 Bottle Tech. All rights reserved.
//

#import "CLCLogFormatter.h"

@implementation CLCLogFormatter

- (instancetype)initWithColorAndPrefix:(BOOL)logColor prefix:(NSString *)prefix {
    self = [super init];
    if (self) {
        self.logColor = logColor;
        self.prefix = prefix;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _logColor = false;
        _prefix = @"";
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
    NSString *logPrefix;
    NSString *logLevel;
    switch (logMessage->_flag) {
        case DDLogFlagError:
            logPrefix = @"\e[31m";
            logLevel = @"Error";
            break;
        case DDLogFlagWarning:
            logPrefix = @"\e[33m";
            logLevel = @"Warning";
            break;
        case DDLogFlagInfo:
            logPrefix = @"\e[32m";
            logLevel = @"Info";
            break;
        case DDLogFlagDebug:
            logPrefix = @"\e[34m";
            logLevel = @"Debug";
            break;
        default:
            logPrefix = @"\e[37m";
            logLevel = @"Verbose";
            break;
    }
    NSString *logSuffix = @"\e[37m";
    NSString *logBusinessPrefix = @"";
    if ([_prefix isEqualToString:@""]) {
        logBusinessPrefix = [NSString stringWithFormat:@"[%@]", _prefix];
    }
    NSLocale *locale = [NSLocale autoupdatingCurrentLocale];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //    dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    //    dateFormatter.timeStyle = NSDateFormatterFullStyle;
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    dateFormatter.locale = locale;
    if (_logColor) {
        //控制台日志格式:  颜色前缀[前缀][日期][logLevel][QueueLabel][文件:行号]日志内容颜色后缀
        return [NSString stringWithFormat:@"%@[%@]%@[%@][%@][tid:%@][%@:%lu]%@%@", logPrefix,
                                          [dateFormatter stringFromDate:logMessage->_timestamp], logBusinessPrefix,
                                          logLevel, logMessage -> _queueLabel, logMessage -> _threadID,
                                          logMessage -> _fileName, (unsigned long)logMessage -> _line,
                                          logMessage -> _message, logSuffix];
    } else {
        //文件日志格式:  [日期][前缀][logLevel][queueLabel][文件:行号]日志内容
        return [NSString stringWithFormat:@"[%@]%@[%@][%@][%@:%lu]%@",
                                          [dateFormatter stringFromDate:logMessage->_timestamp], logBusinessPrefix,
                                          logLevel, logMessage -> _queueLabel, logMessage -> _fileName,
                                          (unsigned long)logMessage -> _line, logMessage -> _message];
    }
}
@end
