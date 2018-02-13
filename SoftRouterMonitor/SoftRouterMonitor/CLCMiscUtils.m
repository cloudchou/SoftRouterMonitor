
#import "CLCMiscUtils.h"
#import "CLCShellUtils.h"

@implementation CLCMiscUtils {

}

+ (BOOL)isSoftRouterStarted {
    //    /usr/local/bin/VBoxManage list runningvms | grep lede-v2.6-x64
    // 注意: 已将App的Sandbox选项关闭了，否则执行/usr/local/bin/VBoxManage命令会抛权限错误 Operation Not Permitted
    NSString *output = [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage list runningvms"];
    return [output containsString:@"lede-v2.6-x64"];
}

+(BOOL)isInterfaceEnabled:(NSString *)interfaceName{
    NSString *interfaceStatusCmd =
        [NSString stringWithFormat:@"networksetup  -getinfo '%@' | grep '^Router:'| awk '{print $2}'", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:interfaceStatusCmd];
    return ![output isEqualToString:@""];
}

+(NSString *)getInterfaceDns:(NSString *)interfaceName{
    NSString *dnsServerCmd = [NSString stringWithFormat:@"sudo networksetup -getdnsservers '%@'", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:dnsServerCmd];
    return output;
}
@end