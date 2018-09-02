//
//  CLCViewHolder.h
//  SoftRouterMonitor
//
//  Created by CloudChou on 2018/9/2.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLCStatusMenuController.h"

@interface CLCViewHolder : NSObject

@property(nonatomic, strong) CLCStatusMenuController *menuController;

+ (instancetype)instance;

- (void)setStatusMenuController:(CLCStatusMenuController*)menuController;

@end
