
#import "CLCMiscUtils.h"
#import "CLCShellExecutor.h"
#import "CLCShellUtils.h"

@implementation CLCMiscUtils {
}

+ (BOOL)isSoftRouterStarted {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    //    /usr/local/bin/VBoxManage list runningvms | grep openwrt-koolshare-v2.22-x64
    // 注意: 已将App的Sandbox选项关闭了，否则执行/usr/local/bin/VBoxManage命令会抛权限错误 Operation Not Permitted
    NSString *output = [CLCShellUtils doShellScript:@"/usr/local/bin/VBoxManage list runningvms"];
    return output != nil && [output containsString:[self getSoftRouterVmName]];
}

+ (void)waitForSoftRouterVmStarted:(NSInteger)timeout {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
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
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    //    NSString *cmd =@"/usr/local/bin/VBoxManage controlvm openwrt-koolshare-v2.22-x64 savestate";
    //    [CLCShellUtils doShellScript:cmd];
    NSString *cmd =
        [NSString stringWithFormat:@"/usr/local/bin/VBoxManage controlvm %@ poweroff ", [self getSoftRouterVmName]];
    [CLCShellUtils doShellScript:cmd];
}

+ (void)startSoftRouterVm {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    BOOL wifiEnabled = [self isInterfaceEnabled:INTERFACE_WIFI];
    BOOL usbEnabled = [self isInterfaceEnabled:INTERFACE_USB];
    NSString *softRouterVmName = [self getSoftRouterVmName];
    if (wifiEnabled && usbEnabled) {
        [CLCShellUtils
            doShellScript:[NSString stringWithFormat:
                                        @"/usr/local/bin/VBoxManage modifyvm %@ --nic2 bridged  --bridgeadapter2 en7",
                                        softRouterVmName]];
        [CLCShellUtils
            doShellScript:[NSString stringWithFormat:
                                        @"/usr/local/bin/VBoxManage modifyvm %@ --nic3 bridged  --bridgeadapter3 en0",
                                        softRouterVmName]];
    } else if (wifiEnabled) {
        [CLCShellUtils doShellScript:[NSString stringWithFormat:@"/usr/local/bin/VBoxManage modifyvm %@ --nic2 none",
                                                                softRouterVmName]];
        [CLCShellUtils
            doShellScript:[NSString stringWithFormat:
                                        @"/usr/local/bin/VBoxManage modifyvm %@ --nic3 bridged  --bridgeadapter3 en0",
                                        softRouterVmName]];
    } else if (usbEnabled) {
        [CLCShellUtils
            doShellScript:[NSString stringWithFormat:
                                        @"/usr/local/bin/VBoxManage modifyvm %@ --nic2 bridged  --bridgeadapter2 en7",
                                        softRouterVmName]];
        [CLCShellUtils doShellScript:[NSString stringWithFormat:@"/usr/local/bin/VBoxManage modifyvm %@ --nic3 none",
                                                                softRouterVmName]];
    } else {
        [CLCShellUtils doShellScript:[NSString stringWithFormat:@"/usr/local/bin/VBoxManage modifyvm %@ --nic2 none",
                                                                softRouterVmName]];
        [CLCShellUtils doShellScript:[NSString stringWithFormat:@"/usr/local/bin/VBoxManage modifyvm %@ --nic3 none",
                                                                softRouterVmName]];
    }
    [CLCShellUtils
        doShellScript:[NSString stringWithFormat:@"nohup /usr/local/bin/VBoxHeadless -s %@ &", softRouterVmName]
        waitForOutput:NO];
}

+ (BOOL)isSoftRouterVmParamOkay {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    BOOL wifiEnabled = [self isInterfaceEnabled:INTERFACE_WIFI];
    BOOL usbEnabled = [self isInterfaceEnabled:INTERFACE_USB];
    BOOL vmWifiEnabled = [self isVmInterfaceEnabled:@"en0"];
    BOOL vmUsbEnabled = [self isVmInterfaceEnabled:@"en7"];
    if (wifiEnabled != vmWifiEnabled) {
        DDLogVerbose(@"vm wifi setting need to change");
        return NO;
    }
    BOOL usbSettingSame = usbEnabled == vmUsbEnabled;
    if (!usbSettingSame) {
        DDLogVerbose(@"vm usb setting need to change");
    }
    return usbSettingSame;
}

+ (BOOL)isVmInterfaceEnabled:(NSString *)interfaceName {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *softRouterVmName = [self getSoftRouterVmName];
    NSString *interfaceStatusCmd =
        [NSString stringWithFormat:@"/usr/local/bin/VBoxManage showvminfo %@ | grep -E 'NIC (2|3)' |grep '%@' ",
                                   softRouterVmName, interfaceName];
    NSString *output = [CLCShellUtils doShellScript:interfaceStatusCmd];
    return output != nil && ![output isEqualToString:@""];
}

+ (BOOL)isInterfaceEnabled:(NSString *)interfaceName {
    DDLogVerbose(@"%@ : %@", NSStringFromSelector(_cmd), interfaceName);
    NSString *interfaceStatusCmd =
        [NSString stringWithFormat:@"networksetup  -getinfo '%@' | grep '^Router:'| awk '{print $2}'", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:interfaceStatusCmd];
    return output != nil && ![output isEqualToString:@""];
}

+ (NSString *)getInterfaceDns:(NSString *)interfaceName {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *dnsServerCmd = [NSString stringWithFormat:@"sudo networksetup -getdnsservers '%@'", interfaceName];
    NSString *output = [CLCShellUtils doShellScript:dnsServerCmd];
    NSString *temp = [output stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return temp;
}

+ (NSString *)getDefaultGateway {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    // status=`ssh root@192.168.100.1 "curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code}
    // https://www.google.com.tw"`
    return [CLCShellUtils doShellScript:@"sudo route  -n get default | grep gateway | cut -d':' -f 2 | tr -d ' '"];
}

+ (BOOL)isSoftRouterDefaultGateWay {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *output = [self getDefaultGateway];
    return output != nil && [output containsString:@"192.168.100.1"];
}

+ (NSString *)getSoftRouterVmName {
    return @"openwrt-koolshare-v2.15-x64";
}

+ (BOOL)isSoftRouterVmForeignNetOkay {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *cmd =
        @"ssh root@192.168.100.1 'curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} "
        @"https://www.google.com.tw'";
    CLCShellExecutor *shellExecutor = [[CLCShellExecutor alloc] init];
    NSString *output = [shellExecutor doShellScript:cmd];
    return output != nil && [output containsString:@"200"];
}

+ (BOOL)isSoftRouterVmHomeNetOkay {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *cmd =
        @"ssh root@192.168.100.1 'curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} "
        @"https://www.baidu.com'";
    CLCShellExecutor *shellExecutor = [[CLCShellExecutor alloc] init];
    NSString *output = [shellExecutor doShellScript:cmd];
    return output != nil && [output containsString:@"200"];
}

+ (BOOL)isSoftRouterShadowSocksServiceStarted {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *cmd = @"ssh root@192.168.100.1 'pgrep -l ss|grep redir'";
    CLCShellExecutor *shellExecutor = [[CLCShellExecutor alloc] init];
    NSString *output = [shellExecutor doShellScript:cmd];
    return output != nil && [output containsString:@"redir"];
}

+ (void)startSoftRouterShadowSocksService {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *cmd = @"ssh root@192.168.100.1 '/koolshare/ss/ssstart.sh start'";
    NSString *output = [CLCShellUtils doShellScript:cmd waitForOutput:YES];
    DDLogVerbose(@"start soft router shadow socks service output : %@", output);
}

+ (BOOL)isForeignNetOkay {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *cmd = @"curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} https://www.google.com.tw";
    CLCShellExecutor *shellExecutor = [[CLCShellExecutor alloc] init];
    NSString *output = [shellExecutor doShellScript:cmd];
    return output != nil && [output containsString:@"200"];
}

+ (BOOL)isHomeNetOkay {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *cmd = @"curl -o /dev/null -s -m 30  --connect-timeout 30 -w %{http_code} https://www.baidu.com";
    CLCShellExecutor *shellExecutor = [[CLCShellExecutor alloc] init];
    NSString *output = [shellExecutor doShellScript:cmd];
    return output != nil && [output containsString:@"200"];
}

+ (void)connectNetToSoftRouter {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
    NSString *softRouterIp = @"192.168.100.1";
    if ([self isInterfaceEnabled:INTERFACE_USB]) {
        NSString *cmd =
            [NSString stringWithFormat:@"sudo networksetup -setdnsservers \"%@\" %@", INTERFACE_USB, softRouterIp];
        [CLCShellUtils doShellScript:cmd];
    } else if ([self isInterfaceEnabled:INTERFACE_WIFI]) {
        NSString *cmd =
            [NSString stringWithFormat:@"sudo networksetup -setdnsservers \"%@\" %@", INTERFACE_WIFI, softRouterIp];
        [CLCShellUtils doShellScript:cmd];
    }
    NSString *cmd = [NSString stringWithFormat:@"sudo route change default %@", softRouterIp];
    [CLCShellUtils doShellScript:cmd];
}

+ (void)connectNetToRealRouter {
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
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
    DDLogVerbose(@"%@", NSStringFromSelector(_cmd));
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
