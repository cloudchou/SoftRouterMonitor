
#import "CLCShellUtils.h"

@implementation CLCShellUtils {

}


+ (NSString *)doShellScript:(NSString *)cmd {
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
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"shell cmd : %@ \noutput :\n %@",cmd, string);
    return string;
}

@end