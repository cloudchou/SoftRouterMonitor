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
#import "CLCViewHolder.h"
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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag{
    DDLogDebug(@"applicationShouldHandleReopen, window visible:  %d ",flag);
    CLCStatusMenuController *statusMenuController=[CLCViewHolder instance].menuController;
    if(statusMenuController == nil){
        DDLogError(@"status menu controller is nil, strange why ?");
        return YES;
    }
    if(flag){ // found any visible windows in your
        if(statusMenuController.mainWindowController.window == nil){
            DDLogError(@"reopen found visible window but access window is nil, why ");
            return YES;
        }
        [statusMenuController.mainWindowController.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
        [NSApp activateIgnoringOtherApps:YES];
    }else{
        [statusMenuController.mainWindowController showWindow:statusMenuController];
    }
    return NO;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
