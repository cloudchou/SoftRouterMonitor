
#import "CLCMiscUtils.h"
#import "CLCNetInterfaceStatusManager.h"
#import "CLCSoftRouterManager.h"
#import "Reachability.h"

static NSString *reachabilityFlags(SCNetworkReachabilityFlags flags) {
    return [NSString stringWithFormat:@"%c%c %c%c%c%c%c%c%c",
#if TARGET_OS_IPHONE
                                      (flags & kSCNetworkReachabilityFlagsIsWWAN) ? 'W' : '-',
#else
                                      'X',
#endif
                                      (flags & kSCNetworkReachabilityFlagsReachable) ? 'R' : '-',
                                      (flags & kSCNetworkReachabilityFlagsConnectionRequired) ? 'c' : '-',
                                      (flags & kSCNetworkReachabilityFlagsTransientConnection) ? 't' : '-',
                                      (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
                                      (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) ? 'C' : '-',
                                      (flags & kSCNetworkReachabilityFlagsConnectionOnDemand) ? 'D' : '-',
                                      (flags & kSCNetworkReachabilityFlagsIsLocalAddress) ? 'l' : '-',
                                      (flags & kSCNetworkReachabilityFlagsIsDirect) ? 'd' : '-'];
}

@interface CLCNetInterfaceStatusManager ()
@property(nonatomic, strong) Reachability *reachability;
@end

@implementation CLCNetInterfaceStatusManager {
}

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [Reachability reachabilityForLocalWiFi];
        _reachability.reachabilityBlock = ^(Reachability *reachability, SCNetworkConnectionFlags flags) {
          DDLogDebug(@"=======> reachability change : %@", reachabilityFlags(flags));
        };
        _reachability.reachableBlock = ^(Reachability *reachability) {
          DDLogDebug(@"=======> reachability reachable");
          dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_SERIAL, 0);
          dispatch_async(queue, ^{
            [self doWhenNetReachable];
          });
        };
        _reachability.unreachableBlock = ^(Reachability *reachability) {
          DDLogDebug(@"=======> reachability change unreachable");
          dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_SERIAL, 0);
          dispatch_async(queue, ^{
            [self doWhenNetUnreachable];
          });
        };
    }
    return _reachability;
}

+ (instancetype)instance {
    static CLCNetInterfaceStatusManager *instance;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
      instance = [CLCNetInterfaceStatusManager new];
    });

    return instance;
}

- (void)startWork {
    [self.reachability startNotifier];
}

- (void)doWhenNetUnreachable {
    DDLogDebug(@"do nothing when net unreachable");
}

- (void)doWhenNetReachable {
    BOOL isUserPreferSoftRouterNet = [self isUserPreferSoftRouterNet];
    DDLogDebug(@"network reachable now. user prefer soft router net : %ld", isUserPreferSoftRouterNet);
    if (isUserPreferSoftRouterNet) {
        DDLogDebug(
            @"user prefer soft router net, and network is reachable now, we need to ensure connect to soft router net "
            @"and net ok");
        [[CLCSoftRouterManager instance] ensureConnectToHealthySoftRouter];
    } else {
        DDLogDebug(
            @"user prefer real router net, and network is reachable now, we need to ensure connect to real router "
            @"net ");
        BOOL userPreferSoftRouterStarted = [self isUserPreferSoftRouterStarted];
        if (userPreferSoftRouterStarted) {
            DDLogDebug(@"user prefer soft router started, so need to start soft router");
            [[CLCSoftRouterManager instance] ensureConnectToRealRouter:YES];
        } else {
            DDLogDebug(@"user prefer soft router stop, so need to stop soft router");
            [[CLCSoftRouterManager instance] ensureConnectToRealRouter:NO];
        }
    }
}

- (BOOL)isUserPreferSoftRouterNet {
    BOOL preferRealRouter = [[NSUserDefaults standardUserDefaults] boolForKey:NS_USER_DEF_KEY_USER_PREFER_REAL_ROUTER];
    return !preferRealRouter;
}

/**
 * 用户是想开启虚拟机还是想停止虚拟机  只要用户上一次操作是停止虚拟机 则认为更倾向于停止虚拟机
 * @return 如果用户想开启虚拟机则返回true 否则返回false
 */
- (BOOL)isUserPreferSoftRouterStarted {
    BOOL userPreferSoftRouterStarted =
        [[NSUserDefaults standardUserDefaults] boolForKey:NS_USER_DEF_KEY_USER_PREFER_SOFT_ROUTER_STARTED];
    return userPreferSoftRouterStarted;
}

@end
