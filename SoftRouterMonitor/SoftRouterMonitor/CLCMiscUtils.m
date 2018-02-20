
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

+ (void)waitForSoftRouterVmStarted:(NSInteger)timeout {
    DDLogVerbose(@"waitForSoftRouterVmStarted");
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (true) {
        DDLogVerbose(@"test soft router vm is started");
        NSString *output = [CLCShellUtils doShellScript:@"ping -c 1 192.168.100.1 -W 1"];
        if (![output containsString:@"Host is down"]) {
            return;
        }
        sleep(1);
        DDLogDebug(@"soft router vm is not  started");
        if ([[NSDate date] timeIntervalSince1970] > [timeoutDate timeIntervalSince1970]) {
            DDLogError(@"soft router vm is not started. and time out");
            return;
        }
    }
}

+ (void)stopSoftRouterVm {
    //    NSString *cmd =@"/usr/local/bin/VBoxManage controlvm lede-v2.6-x64 savestate";
    //    [CLCShellUtils doShellScript:cmd];
    [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage controlvm lede-v2.6-x64 poweroff"];
}

+ (void)startSoftRouterVm {
    BOOL wifiEnabled = [self isInterfaceEnabled:INTERFACE_WIFI];
    BOOL usbEnabled = [self isInterfaceEnabled:INTERFACE_USB];
    if (wifiEnabled && usbEnabled) {
        [CLCShellUtils
            doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic2 bridged  --bridgeadapter2 en7"];
        [CLCShellUtils
            doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic3 bridged  --bridgeadapter3 en0"];
    } else if (wifiEnabled) {
        [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic2 none"];
        [CLCShellUtils
            doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic3 bridged  --bridgeadapter3 en0"];
    } else if (usbEnabled) {
        [CLCShellUtils
            doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic2 bridged  --bridgeadapter2 en7"];
        [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic3 none"];
    } else {
        [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic3 none"];
        [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage modifyvm lede-v2.6-x64 --nic3 none"];
    }
    [CLCShellUtils doShellScript:@"nohup /usr/local/bin/VBoxHeadless -s lede-v2.6-x64 &" waitForOutput:NO];
}

+ (BOOL)isSoftRouterVmParamOkay {
    BOOL wifiEnabled = [self isInterfaceEnabled:INTERFACE_WIFI];
    BOOL usbEnabled = [self isInterfaceEnabled:INTERFACE_USB];
    BOOL vmWifiEnabled = [self isInterfaceEnabled:@"en0"];
    BOOL vmUsbEnabled = [self isInterfaceEnabled:@"en7"];
    if(wifiEnabled!=vmWifiEnabled)
        return NO;
    return usbEnabled == vmUsbEnabled;
}

+(BOOL)isVmInterfaceEnabled:(NSString *)interfaceName{
    NSString *interfaceStatusCmd =
        [NSString stringWithFormat:@"/usr/local/bin/VBoxManage showvminfo lede-v2.6-x64 | grep -E 'NIC (2|3)' |grep '%@' ", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:interfaceStatusCmd];
    return ![output isEqualToString:@""];
}

+ (BOOL)isInterfaceEnabled:(NSString *)interfaceName {
    NSString *interfaceStatusCmd =
        [NSString stringWithFormat:@"networksetup  -getinfo '%@' | grep '^Router:'| awk '{print $2}'", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:interfaceStatusCmd];
    return ![output isEqualToString:@""];
}

+ (NSString *)getInterfaceDns:(NSString *)interfaceName {
    NSString *dnsServerCmd = [NSString stringWithFormat:@"sudo networksetup -getdnsservers '%@'", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:dnsServerCmd];
    return output;
}

+ (NSString *)getDefaultGateway {
    // status=`ssh root@192.168.100.1 "curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code}
    // https://www.google.com.tw"`
    return [CLCShellUtils doShellScript:@"sudo route  -n get default | grep gateway | cut -d':' -f 2 | tr -d ' '"];
}

+ (BOOL)isSoftRouterDefaultGateWay {
    NSString *output = [self getDefaultGateway];
    return [output containsString:@"192.168.100.1"];
}

+ (BOOL)isSoftRouterVmForeignNetOkay {
    NSString *cmd =
        @"ssh root@192.168.100.1 'curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} "
        @"https://www.google.com.tw'";
    NSString *output = [CLCShellUtils doShellScript:cmd];
    return [output containsString:@"200"];
}

+ (BOOL)isSoftRouterVmHomeNetOkay {
    NSString *cmd =
        @"ssh root@192.168.100.1 'curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} "
        @"https://www.baidu.com'";
    NSString *output = [CLCShellUtils doShellScript:cmd];
    return [output containsString:@"200"];
}

+ (BOOL)isForeignNetOkay {
    NSString *cmd = @"curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} https://www.google.com.tw";
    NSString *output = [CLCShellUtils doShellScript:cmd];
    return [output containsString:@"200"];
}

+ (BOOL)isHomeNetOkay {
    NSString *cmd = @"curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} https://www.baidu.com";
    NSString *output = [CLCShellUtils doShellScript:cmd];
    return [output containsString:@"200"];
}

+ (void)connectNetToSoftRouter {
    NSString *softRouterIp = @"192.168.100.1";
    if ([self isInterfaceEnabled:INTERFACE_USB]) {
        NSString *cmd =
            [NSString stringWithFormat:@"sudo networksetup -setdnsservers %@ %@", INTERFACE_USB, softRouterIp];
        [CLCShellUtils doShellScript:cmd];
    } else if ([self isInterfaceEnabled:INTERFACE_WIFI]) {
        NSString *cmd =
            [NSString stringWithFormat:@"sudo networksetup -setdnsservers %@ %@", INTERFACE_WIFI, softRouterIp];
        [CLCShellUtils doShellScript:cmd];
    }
    NSString *cmd = [NSString stringWithFormat:@"sudo route change default %@", softRouterIp];
    [CLCShellUtils doShellScript:cmd];
}

+ (void)connectNetToRealRouter {
    NSString *cmd =
        @"sudo sed -i -e 's/<string>192.168.100.1<\\/string>//g' "
        @"/Library/Preferences/SystemConfiguration/preferences.plist";
    [CLCShellUtils doShellScript:cmd];
    NSString *gateway = @"";
    if ([self isInterfaceEnabled:INTERFACE_USB]) {
        NSString *interfaceStatusCmd = [NSString
            stringWithFormat:@"networksetup  -getinfo '%@' | grep '^Router:'| awk '{print $2}'", INTERFACE_USB];
        gateway = [CLCShellUtils doShellScript:interfaceStatusCmd];
    } else if ([self isInterfaceEnabled:INTERFACE_WIFI]) {
        NSString *interfaceStatusCmd = [NSString
            stringWithFormat:@"networksetup  -getinfo '%@' | grep '^Router:'| awk '{print $2}'", INTERFACE_WIFI];
        gateway = [CLCShellUtils doShellScript:interfaceStatusCmd];
    }
    if (![gateway isEqualToString:@""]) {
        cmd = [NSString stringWithFormat:@"sudo route change default %@", gateway];
        [CLCShellUtils doShellScript:cmd];
    } else {
        DDLogError(@"no usb or wifi net connected");
    }
}

+ (void)waitForSoftRouterHomeNetOk:(NSInteger)timeout {
    DDLogVerbose(@"waitForSoftRouterHomeNetOk");
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (true) {
        DDLogVerbose(@"test soft router vm home net is ok");
        if ([self isSoftRouterVmHomeNetOkay]) {
            DDLogVerbose(@"soft router vm home net is ok");
            return;
        }
        sleep(1);
        DDLogDebug(@"soft router vm home net is not ok");
        if ([[NSDate date] timeIntervalSince1970] > [timeoutDate timeIntervalSince1970]) {
            DDLogError(@"soft router vm home net is not ok. and time out");
            return;
        }
    }
}

@end