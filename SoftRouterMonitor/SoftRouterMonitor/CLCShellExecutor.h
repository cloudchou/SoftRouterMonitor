//  CLCShellExecutor.h
//  Description：
//
// Created by CloudChou on 2018/6/5.
// Copyright (c) 2018 CloudChou. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface CLCShellExecutor : NSObject

- (NSString *)doShellScript:(NSString *)cmd;

@end