//
//  CLCHttpServer.h
//  SoftRouterMonitor
//
//  Created by CloudChou on 2018/9/1.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLCHttpServer : NSObject

+ (instancetype)instance;

- (void)startWork;

@end
