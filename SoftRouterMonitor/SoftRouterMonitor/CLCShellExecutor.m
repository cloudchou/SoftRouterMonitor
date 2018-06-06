
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
    NSDate *timeoutTime = [NSDate dateWithTimeInterval:30 sinceDate:currentTime];
    while (!terminated) {
        BOOL runLoopResult = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutTime];
        DDLogVerbose(@"run loop end result : %d", runLoopResult);
        if ([[NSDate date] timeIntervalSince1970] > [timeoutTime timeIntervalSince1970]) {
            DDLogVerbose(@"now execute cmd timeout : %@", cmd);
            break;
        }
    }
    DDLogVerbose(@"shell cmd : %@ \noutput :\n %@", cmd, cmdOutput);
    return cmdOutput;
}

- (void)outData:(NSNotification *)notification {
    NSFileHandle *outputFile = (NSFileHandle *)[notification object];
    while (YES) {
        NSData *data = [outputFile availableData];
        if ([data length]) {
            NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [cmdOutput appendString:temp];
            DDLogVerbose(@"shell cmd : %@ temp output :\n %@", executingCmd, temp);
        } else {
            break;
        }
    }

    [outputFile waitForDataInBackgroundAndNotify];
}

- (void)terminated:(NSNotification *)notification {
    NSLog(@"Task terminated, cmd : %@", executingCmd);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    terminated = YES;
}

@end