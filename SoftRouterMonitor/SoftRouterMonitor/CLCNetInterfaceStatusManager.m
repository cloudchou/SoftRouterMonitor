
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
        DDLogDebug(@"user prefer soft router net, and network is reachable now, we need to ensure connect to soft router net and net ok");
        [[CLCSoftRouterManager instance]ensureConnectToHealthySoftRouter];
    } else {
        [self connectToRealRouterIfNeed];
    }
}

- (void)connectToRealRouterIfNeed {
    BOOL softRouterDefaultGateWay = [CLCMiscUtils isSoftRouterDefaultGateWay];
    if (softRouterDefaultGateWay) {
        DDLogDebug(
            @"user  prefer real router net, but soft router is default gateway, so need to connect to real router and "
            @"stop soft router vm ");
        [[CLCSoftRouterManager instance] connectNetToRealRouter];
        [[CLCSoftRouterManager instance] stopSoftRouterVm];
    } else {
        DDLogDebug(@"user  prefer real router net soft router is not default gateway check dns");
        BOOL wifiEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_WIFI];
        if (wifiEnabled) {
            NSString *wifiDns = [CLCMiscUtils getInterfaceDns:INTERFACE_WIFI];
            if ([wifiDns isEqualToString:@"192.168.100.1"]) {
                DDLogDebug(
                    @"user user real soft router net， but wifi dns is soft router, so need to  connect to real and "
                    @"stop soft router vm router" );
                [[CLCSoftRouterManager instance] connectNetToRealRouter];
                return;
            }
        }
        BOOL usbEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_USB];
        if (usbEnabled) {
            NSString *usbDns = [CLCMiscUtils getInterfaceDns:INTERFACE_USB];
            if ([usbDns isEqualToString:@"192.168.100.1"]) {
                DDLogDebug(
                    @"user user real soft router net， but usb dns is soft router, so need to  connect to real and "
                    @"stop soft router vm router");
                [[CLCSoftRouterManager instance] connectNetToRealRouter];
                return;
            }
        }
    }
}

- (BOOL)isUserPreferSoftRouterNet {
    // TODO
    return YES;
}

@end