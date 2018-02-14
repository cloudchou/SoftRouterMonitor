//  CLCSoftRouterManager.h
//  Description：
//
// Created by CloudChou on 14/02/2018.
// Copyright (c) 2018 CloudChou. All rights reserved.
//
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, SoftRouterOperateStatus) {
  SoftRouterOperateStatusNone,
  SoftRouterOperateStatusComputing,
  SoftRouterOperateStatusStarting,
  SoftRouterOperateStatusStopping,
  SoftRouterOperateStatusConnectingToSoftRouter,
  SoftRouterOperateStatusConnectingToRealRouter,
};

@interface CLCSoftRouterManager : NSObject

@property(nonatomic, assign) SoftRouterOperateStatus operateStatus;

+ (instancetype)instance;

- (void)toggleSoftRouterVm;

- (void)connectNetToSoftRouter;

- (void)connectNetToRealRouter;

@end