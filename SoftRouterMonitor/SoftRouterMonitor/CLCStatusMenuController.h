//  CLCStatusMenuController.h
//  Description：
//    TODO(请补充文件用途)
// Created by CloudChou on 11/02/2018.
// Copyright (c) 2018 CloudChou. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface CLCStatusMenuController : NSObject
@property (weak) IBOutlet NSMenu *statusBarMenu;
@property(nonatomic, strong, readonly) NSWindowController *mainWindowController;
@property (strong) NSStatusItem *statusItem;
@end
