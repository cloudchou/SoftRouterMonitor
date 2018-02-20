
#import "CLCMiscUtils.h"
#import "CLCSoftRouterManager.h"
#import "ReactiveObjC/ReactiveObjC.h"

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
          }
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)connectNetToSoftRouter {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusConnectingToSoftRouter;
        [[RACScheduler scheduler] schedule:^{
          [CLCMiscUtils connectNetToSoftRouter];
          self.operateStatus = SoftRouterOperateStatusNone;
        }];
    }
}

- (void)connectNetToRealRouter {
    if (self.operateStatus == SoftRouterOperateStatusNone) {
        self.operateStatus = SoftRouterOperateStatusConnectingToRealRouter;
        [[RACScheduler scheduler] schedule:^{
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

-(void)ensureConnectToHealthySoftRouter2{
    //1. 先保证软路由已正常启动 (如果需要重启，则先将网络切换到 真实路由)
    BOOL softRouterStarted = [CLCMiscUtils isSoftRouterStarted];
    if(!softRouterStarted){
        //先保证虚拟机参数正确 然后启动虚拟机 并且等待网络Ok

    }else{
        //判断虚拟机参数是否正确 如果不正确 则重启虚拟机 并且等待网络Ok
    }
    //2. 将默认路由切换到软路由

}

@end