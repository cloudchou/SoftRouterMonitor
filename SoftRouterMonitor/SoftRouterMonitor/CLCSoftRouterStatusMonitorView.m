//
//  CLCSoftRouterStatusMonitorView.m
//  SoftMonitor
//
//  Created by CloudChou on 13/02/2018.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import <ReactiveObjC/RACSignal.h>
#import <ReactiveObjC/RACScheduler.h>
#import "CLCMiscUtils.h"
#import "CLCShellUtils.h"
#import "CLCSoftRouterStatusMonitorView.h"

@interface CLCSoftRouterStatusMonitorView ()
@property(weak) IBOutlet NSTextField *vmStatusLabel;
@property(weak) IBOutlet NSTextField *wifiDnsStatusLabel;
@property(weak) IBOutlet NSTextField *usbDnsStatusLabel;
@property(weak) IBOutlet NSTextField *defaultGatewayStatusLabel;
@property(weak) IBOutlet NSTextField *softRouterForeignNetStatusLabel;
@property(weak) IBOutlet NSTextField *softRouterHomeNetStatusLabel;
@property(weak) IBOutlet NSButtonCell *switchVmButton;

@end

@implementation CLCSoftRouterStatusMonitorView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self restoreStatus];
    [self updateSoftRouterVmStatus];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
}

- (void)restoreStatus {
    [self.switchVmButton setEnabled:NO];
    [self.vmStatusLabel setStringValue:@"计算中..."];
    [self.wifiDnsStatusLabel setStringValue:@"计算中..."];
    [self.usbDnsStatusLabel setStringValue:@"计算中..."];
    [self.defaultGatewayStatusLabel setStringValue:@"计算中..."];
    [self.softRouterForeignNetStatusLabel setStringValue:@"计算中..."];
    [self.softRouterHomeNetStatusLabel setStringValue:@"计算中..."];
}

- (IBAction)onVmStatusSwitchClicked:(id)sender {
    [self updateSwitchVmButtonTitle:@"正在停止..."];
    [self updateSoftRouterVmStatus];
    [self updateSwitchVmButtonTitle:@"正在启动"];
    [self updateSoftRouterVmStatus];
}

-(void)updateSwitchVmButtonTitle:(NSString *)title{
    dispatch_sync(dispatch_get_main_queue(), ^{
      [self.switchVmButton setTitle:title];
    });
}

- (IBAction)onSwitchNetToSoftRouter:(id)sender {
}

- (IBAction)onSwitchNetToRealRouter:(id)sender {
}

- (void)awakeFromNib {
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown
                                          handler:^NSEvent *(NSEvent *_Nonnull aEvent) {
                                            [self keyDown:aEvent];
                                            return aEvent;
                                          }];
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged
                                          handler:^NSEvent *(NSEvent *_Nonnull aEvent) {
                                            [self flagsChanged:aEvent];
                                            return aEvent;
                                          }];
}

- (void)keyDown:(NSEvent *)event {
    NSEventModifierFlags flags = NSEvent.modifierFlags & NSCommandKeyMask;
    if (flags && event.keyCode == 12)  // command +q
    {
        [NSApplication.sharedApplication terminate:self];
    }
}

- (void)updateSoftRouterVmStatus {
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(bgQueue, ^{
      BOOL started = [CLCMiscUtils isSoftRouterStarted];
      dispatch_sync(dispatch_get_main_queue(), ^{
        if (started) {
            [self.vmStatusLabel setStringValue:@"已启动"];
            [self.switchVmButton setTitle:@"停止"];
        } else {
            [self.vmStatusLabel setStringValue:@"已停止"];
            [self.switchVmButton setTitle:@"启动"];
        }
        [self.switchVmButton setEnabled:YES];
      });
    });
}

@end
