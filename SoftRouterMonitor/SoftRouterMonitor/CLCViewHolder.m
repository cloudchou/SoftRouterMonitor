//
//  CLCViewHolder.m
//  SoftRouterMonitor
//
//  Created by CloudChou on 2018/9/2.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import "CLCViewHolder.h"

@implementation CLCViewHolder

+ (instancetype)instance {
    static CLCViewHolder *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [CLCViewHolder new];
    });
    return instance;
}

- (void)setStatusMenuController:(CLCStatusMenuController*)menuController{
    self.menuController = menuController;
}

@end
