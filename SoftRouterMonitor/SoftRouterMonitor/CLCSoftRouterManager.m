
#import "CLCMiscUtils.h"
#import "CLCSoftRouterManager.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "CLCNetInterfaceStatusManager.h"

@implementation CLCSoftRouterManager {
}

+ (instancetype)instance {
    static CLCSoftRouterManager *instance;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
      instance = [CLCSoftRouterManager new];
    });

    return instance;
}

- (void)toggleSoftRouterVm {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusComputing;
        [[RACScheduler scheduler] schedule:^{
          BOOL started = [CLCMiscUtils isSoftRouterStarted];
          if (started) {
              self.operateStatus = SoftRouterOperateStatusStopping;
              [CLCMiscUtils stopSoftRouterVm];
              self.operateStatus = SoftRouterOperateStatusNone;
          } else {
              self.operateStatus = SoftRouterOperateStatusStarting;
              [CLCMiscUtils startSoftRouterVm];
              [CLCMiscUtils waitForSoftRouterVmStarted:10];
              self.operateStatus = SoftRouterOperateStatusNone;
          }
        }];
    }
}

- (void)stopSoftRouterVm {
    DDLogVerbose(@"stop soft router vm");
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusComputing;
        [[RACScheduler scheduler] schedule:^{
          BOOL started = [CLCMiscUtils isSoftRouterStarted];
          if (started) {
              DDLogDebug(@"soft router vm is started now stop");
              self.operateStatus = SoftRouterOperateStatusStopping;
              [CLCMiscUtils stopSoftRouterVm];
          } else {
              DDLogDebug(@"soft router vm is already stopped. no need to switch");
          }
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)startSoftRouterVm {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusComputing;
        [[RACScheduler scheduler] schedule:^{
          BOOL started = [CLCMiscUtils isSoftRouterStarted];
          if (started) {
              DDLogDebug(@"soft router vm is already started ");
          } else {
              DDLogDebug(@"soft router vm is stopped. now start ");
              self.operateStatus = SoftRouterOperateStatusStarting;
              [CLCMiscUtils startSoftRouterVm];
              [CLCMiscUtils waitForSoftRouterVmStarted:10];
          }
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)connectNetToSoftRouter {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusConnectingToSoftRouter;
        [[RACScheduler scheduler] schedule:^{
          [[NSUserDefaults standardUserDefaults] setBool:NO forKey:NS_USER_DEF_KEY_USER_PREFER_REAL_ROUTER];
          [CLCMiscUtils connectNetToSoftRouter];
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)connectNetToRealRouter {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusConnectingToRealRouter;
        [[RACScheduler scheduler] schedule:^{
          [[NSUserDefaults standardUserDefaults] setBool:YES forKey:NS_USER_DEF_KEY_USER_PREFER_REAL_ROUTER];
          [CLCMiscUtils connectNetToRealRouter];
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)ensureConnectToHealthySoftRouter {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusAutoSwitching;
        [[RACScheduler scheduler] schedule:^{
          [self ensureConnectToHealthySoftRouter2];
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)ensureConnectToRealRouter{
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusAutoSwitching;
        [[RACScheduler scheduler] schedule:^{
          [self connectToRealRouterIfNeed];
//          [CLCMiscUtils stopSoftRouterVm];
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)ensureConnectToHealthySoftRouter2 {
    // 1. 先保证软路由已正常启动 (如果需要重启，则先将网络切换到 真实路由)
    BOOL softRouterStarted = [CLCMiscUtils isSoftRouterStarted];
    if (!softRouterStarted) {
        DDLogDebug(@"soft router vm not started. we have to start soft router vm first");
        [CLCMiscUtils startSoftRouterVm];  // 会自动修改软路由虚拟机的参数 然后才启动
        [CLCMiscUtils waitForSoftRouterVmStarted:10];
        [CLCMiscUtils waitForSoftRouterHomeNetOk:30];
    } else {
        //判断虚拟机参数是否正确 如果不正确 则重启虚拟机 并且等待网络Ok
        BOOL softRouterVmParamOkay = [CLCMiscUtils isSoftRouterVmParamOkay];
        if (!softRouterVmParamOkay) {
            DDLogDebug(@"soft router vm param not ok. we have to restart soft router vm first");
            [self connectToRealRouterIfNeed];
            [CLCMiscUtils stopSoftRouterVm];
            [CLCMiscUtils startSoftRouterVm];  // 会自动修改软路由虚拟机的参数 然后才启动
            [CLCMiscUtils waitForSoftRouterVmStarted:10];
            [CLCMiscUtils waitForSoftRouterHomeNetOk:30];
        } else {
            DDLogDebug(@"soft router vm param is ok. no need to restart soft router vm");
        }
    }
    // 2. 判断网络情况 再决定 是否 将默认路由切换到软路由
    BOOL softRouterVmHomeNetOkay = [CLCMiscUtils isSoftRouterVmHomeNetOkay];
    if (softRouterVmHomeNetOkay) {  // 切换到 软路由
        DDLogDebug(@"soft router vm net ok, now we can connect to soft router ");
        [self connectToSoftRouterIfNeed];
    } else {  // 切换到真实路由
        DDLogDebug(@"soft router vm net not ok, now we have to connect to real router ");
        [self connectToRealRouterIfNeed];
    }
}

- (void)connectToRealRouterIfNeed {
    DDLogVerbose(@"connectToRealRouterIfNeed");
    BOOL softRouterDefaultGateWay = [CLCMiscUtils isSoftRouterDefaultGateWay];
    if (softRouterDefaultGateWay) {
        DDLogDebug(@"real router is not default gateway, so need to connect to real router");
        [CLCMiscUtils connectNetToRealRouter];
    } else {
        DDLogDebug(@"real router is  default gateway and have to check dns");
        BOOL wifiEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_WIFI];
        if (wifiEnabled) {
            NSString *wifiDns = [CLCMiscUtils getInterfaceDns:INTERFACE_WIFI];
            if ([wifiDns isEqualToString:@"192.168.100.1"]) {
                DDLogDebug(@"wifi dns is soft router, so need to  switch to real router ");
                [CLCMiscUtils connectNetToRealRouter];
                return;
            }
        }
        BOOL usbEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_USB];
        if (usbEnabled) {
            NSString *usbDns = [CLCMiscUtils getInterfaceDns:INTERFACE_USB];
            if ([usbDns isEqualToString:@"192.168.100.1"]) {
                DDLogDebug(@"usb dns is soft router, so need to  switch to real router ");
                [CLCMiscUtils connectNetToRealRouter];
                return;
            }
        }
        DDLogDebug(@"real router is  the dns for any interfaces correct!!!");
    }
}
- (void)connectToSoftRouterIfNeed {
    DDLogVerbose(@"connectToSoftRouterIfNeed");
    BOOL softRouterDefaultGateWay = [CLCMiscUtils isSoftRouterDefaultGateWay];
    if (!softRouterDefaultGateWay) {
        DDLogDebug(@"soft router is not default gateway, so need to connect to soft router");
        [CLCMiscUtils connectNetToSoftRouter];
    } else {
        DDLogDebug(@"soft router is already default gateway, check dns");
        BOOL wifiEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_WIFI];
        if (wifiEnabled) {
            NSString *wifiDns = [CLCMiscUtils getInterfaceDns:INTERFACE_WIFI];
            if (![wifiDns isEqualToString:@"192.168.100.1"]) {
                DDLogDebug(@"wifi dns is not soft router, so need to  switch to soft router ");
                [CLCMiscUtils connectNetToSoftRouter];
                return;
            }
        }
        BOOL usbEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_USB];
        if (usbEnabled) {
            NSString *usbDns = [CLCMiscUtils getInterfaceDns:INTERFACE_USB];
            if (![usbDns isEqualToString:@"192.168.100.1"]) {
                DDLogDebug(@"usb dns is  not soft router, so need to  switch to soft router ");
                [CLCMiscUtils connectNetToSoftRouter];
                return;
            }
        }
        DDLogDebug(@"soft router is  the dns for all interfaces correct!!!");
    }
}

@end
