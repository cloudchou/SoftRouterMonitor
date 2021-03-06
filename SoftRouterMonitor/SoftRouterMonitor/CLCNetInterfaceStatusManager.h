//  CLCNetInterfaceStatusManager.h
//  Description：
//
// Created by CloudChou on 20/02/2018.
// Copyright (c) 2018 CloudChou. All rights reserved.
//
#import <Foundation/Foundation.h>

#define NS_USER_DEF_KEY_USER_PREFER_REAL_ROUTER @"NS_USER_DEF_KEY_USER_PREFER_REAL_ROUTER"
#define NS_USER_DEF_KEY_USER_PREFER_SOFT_ROUTER_STARTED @"NS_USER_DEF_KEY_USER_PREFER_SOFT_ROUTER_STARTED"

@interface CLCNetInterfaceStatusManager : NSObject

+ (instancetype)instance;

- (void)startWork;

@end