
#import "CLCNetInterfaceStatusManager.h"

@implementation CLCNetInterfaceStatusManager {

}

+ (instancetype)instance {
    static CLCNetInterfaceStatusManager *instance;
    static dispatch_once_t once;

    dispatch_once(&once, ^{
      instance = [CLCNetInterfaceStatusManager new];
    });

    return instance;
}

+ (void)startWork {

}

@end