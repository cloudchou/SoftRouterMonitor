
#import "CLCShellExecutor.h"

@implementation CLCShellExecutor {
    BOOL terminated;
    NSMutableString *cmdOutput;
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
    while (!terminated) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    DDLogVerbose(@"shell cmd : %@ \noutput :\n %@", cmd, cmdOutput);
    return cmdOutput;
}

- (void)outData:(NSNotification *)notification {
    NSFileHandle *outputFile = (NSFileHandle *)[notification object];
    NSData *data = [outputFile availableData];
    if ([data length]) {
        NSString *temp = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [cmdOutput appendString:temp];
    }
    [outputFile waitForDataInBackgroundAndNotify];
}

- (void)terminated:(NSNotification *)notification {
    NSLog(@"Task terminated");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    terminated = YES;
}

@end