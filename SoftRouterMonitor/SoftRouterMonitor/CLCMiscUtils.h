//  CLCMiscUtils.h
//  Description：
//
// Created by CloudChou on 13/02/2018.
// Copyright (c) 2018 CloudChou. All rights reserved.
//
#import <Foundation/Foundation.h>

#define INTERFACE_USB @"USB 10/100 LAN"
#define INTERFACE_WIFI @"Wi-Fi"

@interface CLCMiscUtils : NSObject

+ (void)connectNetToRealRouter;
+ (void)connectNetToSoftRouter;
+ (BOOL)isHomeNetOkay;
+ (BOOL)isForeignNetOkay;
+ (BOOL)isSoftRouterVmHomeNetOkay;
+ (BOOL)isSoftRouterVmForeignNetOkay;
+ (void)waitForSoftRouterVmStarted:(NSInteger)timeout;

+ (BOOL)isInterfaceEnabled:(NSString *)interfaceName;

+ (void)stopSoftRouterVm;

+ (void)startSoftRouterVm;

+ (NSString *)getInterfaceDns:(NSString *)interfaceName;

+ (BOOL)isSoftRouterStarted;

+ (NSString *)getDefaultGateway;

+ (BOOL)isSoftRouterDefaultGateWay;

@end