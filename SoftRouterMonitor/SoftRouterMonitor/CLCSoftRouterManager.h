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
    SoftRouterOperateStatusAutoSwitching,
};

@interface CLCSoftRouterManager : NSObject

@property(nonatomic, assign) SoftRouterOperateStatus operateStatus;

- (void)ensureConnectToHealthySoftRouter;

+ (instancetype)instance;

- (void)toggleSoftRouterVm;

- (void)stopSoftRouterVm;

- (void)startSoftRouterVm;

- (void)connectNetToSoftRouter;

- (void)connectNetToRealRouter;

- (void)ensureConnectToRealRouter;

@end
