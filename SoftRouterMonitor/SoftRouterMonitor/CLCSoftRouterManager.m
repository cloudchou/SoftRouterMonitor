
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

@end