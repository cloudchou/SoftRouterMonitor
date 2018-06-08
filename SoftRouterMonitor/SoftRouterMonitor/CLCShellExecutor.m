
#import "CLCShellExecutor.h"

@implementation CLCShellExecutor {
    BOOL terminated;
    BOOL outputEnded;
    NSMutableString *cmdOutput;
    NSString *executingCmd;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        cmdOutput = [[NSMutableString alloc] init];
        terminated = false;
        outputEnded = false;
    }
    return self;
}

- (NSString *)doShellScript:(NSString *)cmd {
    NSTask *task = [[NSTask alloc] init];  // Make a new task
    NSString *path = @"/bin/bash";
    [task setLaunchPath:path];  // Tell which command we are running
    NSMutableArray<NSString *> *arguments = [[NSMutableArray alloc] init];
    executingCmd = cmd;
    [arguments addObject:@"-c"];
    [arguments addObject:cmd];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];
    [task launch];
    DDLogVerbose(@"try to execute cmd: %@", cmd);
    NSFileHandle *fileHandle = [pipe fileHandleForReading];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(terminated:)
                                                 name:NSTaskDidTerminateNotification
                                               object:task];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dataEnd:)
                                                 name:NSFileHandleReadToEndOfFileCompletionNotification
                                               object:fileHandle];
    //    [fileHandle waitForDataInBackgroundAndNotify];
    NSArray *modes = @[ NSDefaultRunLoopMode ];
    [fileHandle readToEndOfFileInBackgroundAndNotifyForModes:modes];
    NSDate *currentTime = [NSDate date];
    NSDate *timeoutTime = [NSDate dateWithTimeInterval:60 sinceDate:currentTime];
    while (!outputEnded && !terminated) {
        BOOL runLoopResult = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutTime];
        DDLogVerbose(@"run loop end result : %d", runLoopResult);
        if ([[NSDate date] timeIntervalSince1970] > [timeoutTime timeIntervalSince1970]) {
            DDLogVerbose(@"now execute cmd timeout : %@", cmd);
            break;
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //    DDLogVerbose(@"try to read pipe data ");
    //    if (terminated) {
    //        [self readPipeData:fileHandle];
    //    }
    NSTimeInterval timeDiff = [[NSDate date] timeIntervalSince1970] - [currentTime timeIntervalSince1970];
    DDLogVerbose(@"shell output : %@, calculate time : %3.1f second cmd: %@ \n", cmdOutput, timeDiff, cmd);
    if ([cmdOutput isEqualToString:@""]) {
        DDLogDebug(@"cmd output is empty for cmd : %@", cmd);
    }
    [fileHandle closeFile];
    return cmdOutput;
}

- (void)outData:(NSNotification *)notification {
    NSFileHandle *outputFile = (NSFileHandle *)[notification object];
    [self readPipeData:outputFile];
    [outputFile waitForDataInBackgroundAndNotify];
}

- (void)dataEnd:(NSNotification *)notification {
    NSDictionary *dictionary = [notification userInfo];
    NSNumber *errorCode = dictionary[@"NSFileHandleError"];
    if ([errorCode intValue] == 0) {
        NSData *data = dictionary[NSFileHandleNotificationDataItem];
        NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [cmdOutput appendString:temp];
        DDLogVerbose(@"shell temp output : %@ cmd: %@ ", temp, executingCmd);
    }
    outputEnded = true;
}

- (void)readPipeData:(NSFileHandle *)fileHandle {
    DDLogVerbose(@"try to call availableData of file handle");
    @try {
        // availableData 没有数据时 availableData会阻塞 如果读到结尾 会返回 空对象
        // 如果读失败 会抛出异常 NSFileHandleOperationException
        NSData *data = [fileHandle availableData];
        DDLogVerbose(@"try to call availableData of file handle end");
        if ([data length]) {
            NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [cmdOutput appendString:temp];
            DDLogVerbose(@"shell temp output : %@ cmd: %@ ", temp, executingCmd);
        } else {
            DDLogVerbose(@"no data ...");
        }
    } @catch (NSException *exception) {
        DDLogError(@"exception occurred : %@", exception);
    }
}

- (void)terminated:(NSNotification *)notification {
    NSLog(@"Task terminated, cmd : %@", executingCmd);
    terminated = YES;
}

@end