//
//  AppDelegate.m
//  SoftRounterMonitor
//
//  Created by CloudChou on 13/02/2018.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import "AppDelegate.h"
#import "CLCLogger.h"
#import "CLCNetInterfaceStatusManager.h"
// #import "CLCHttpServer.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [CLCLogger initCocoaLumberJackLog:@"SoftRouterMonitor"];
    [[CLCNetInterfaceStatusManager instance] startWork];
    // [[CLCHttpServer instance]startWork];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
