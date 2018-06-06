
#import "CLCShellExecutor.h"

@implementation CLCShellExecutor {
    BOOL terminated;
    NSMutableString *cmdOutput;
    NSString *executingCmd;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        cmdOutput = [[NSMutableString alloc] init];
        terminated = false;
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
                                             selector:@selector(outData:)
                                                 name:NSFileHandleDataAvailableNotification
                                               object:fileHandle];
    [fileHandle waitForDataInBackgroundAndNotify];
    NSDate *currentTime = [NSDate date];
    NSDate *timeoutTime = [NSDate dateWithTimeInterval:60 sinceDate:currentTime];
    while (!terminated) {
        BOOL runLoopResult = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutTime];
        DDLogVerbose(@"run loop end result : %d", runLoopResult);
        if ([[NSDate date] timeIntervalSince1970] > [timeoutTime timeIntervalSince1970]) {
            DDLogVerbose(@"now execute cmd timeout : %@", cmd);
            break;
        }
    }
    DDLogVerbose(@"try to read pipe data ");
    [self readPipeData:fileHandle];
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

- (void)readPipeData:(NSFileHandle *)fileHandle {
    while (YES) {
        DDLogVerbose(@"try to call availableData of file handle");
        @try {
            NSData *data = [fileHandle availableData];
            DDLogVerbose(@"try to call availableData of file handle");
            if ([data length]) {
                NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                [cmdOutput appendString:temp];
                DDLogVerbose(@"shell temp output : %@ cmd: %@ ", temp, executingCmd);
            } else {
                break;
            }
        } @catch (NSException *exception) {
            DDLogError(@"exception occurred : %@", exception);
            break;
        }
    }
}

- (void)terminated:(NSNotification *)notification {
    NSLog(@"Task terminated, cmd : %@", executingCmd);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    terminated = YES;
}

@end