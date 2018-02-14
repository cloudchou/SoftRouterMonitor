
#import "CLCSoftRouterManager.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "CLCMiscUtils.h"

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

- (void)startSoftRouterVm {

}

- (void)toggleSoftRouterVm {
    if(self.operateStatus==SoftRouterOperateStatusNone){
        self.operateStatus = SoftRouterOperateStatusComputing;
        [[RACScheduler scheduler] schedule:^{
          BOOL started = [CLCMiscUtils isSoftRouterStarted];
          if(started){
              self.operateStatus = SoftRouterOperateStatusStopping;
              [CLCMiscUtils stopSoftRouterVm];
              self.operateStatus = SoftRouterOperateStatusNone;
          }else{
              self.operateStatus = SoftRouterOperateStatusStarting;
              [CLCMiscUtils startSoftRouterVm];
              [CLCMiscUtils waitForSoftRouterVmStarted:10];
              self.operateStatus = SoftRouterOperateStatusNone;
          }
        }];
    }
}

- (void)stopSoftRouterVm {

}

- (void)connectNetToSoftRouter {

}

- (void)connectNetToRealRouter {

}

@end