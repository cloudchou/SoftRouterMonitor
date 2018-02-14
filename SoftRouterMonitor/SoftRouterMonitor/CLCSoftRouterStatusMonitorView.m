//
//  CLCSoftRouterStatusMonitorView.m
//  SoftMonitor
//
//  Created by CloudChou on 13/02/2018.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import <ReactiveObjC/ReactiveObjC.h>
#import "CLCMiscUtils.h"
#import "CLCShellUtils.h"
#import "CLCSoftRouterManager.h"
#import "CLCSoftRouterStatusMonitorView.h"

@interface CLCSoftRouterStatusMonitorView ()
@property(nonatomic, weak) IBOutlet NSTextField *vmStatusLabel;
@property(nonatomic, weak) IBOutlet NSTextField *wifiDnsStatusLabel;
@property(nonatomic, weak) IBOutlet NSTextField *usbDnsStatusLabel;
@property(nonatomic, weak) IBOutlet NSTextField *defaultGatewayStatusLabel;
@property(nonatomic, weak) IBOutlet NSTextField *softRouterForeignNetStatusLabel;
@property(nonatomic, weak) IBOutlet NSTextField *softRouterHomeNetStatusLabel;
@property(nonatomic, weak) IBOutlet NSButtonCell *switchVmButton;
@property(nonatomic, weak) RACDisposable *updateSoftRouterVmStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateUsbDnsStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateWifiDnsStatusDisposable;
@end

@implementation CLCSoftRouterStatusMonitorView

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (void)viewWillAppear {
    [super viewWillAppear];
    [self restoreStatus];
    [self monitorToUpdateAllViews];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    [self stopUpdateTask];
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
    [[CLCSoftRouterManager instance] toggleSoftRouterVm];
    //    [self updateSwitchVmButtonTitle:@"正在停止..."];
    //    [self updateSoftRouterVmStatus];
    //    [self updateSwitchVmButtonTitle:@"正在启动"];
    //    [self updateSoftRouterVmStatus];
}

- (void)updateSwitchVmButtonTitle:(NSString *)title {
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

- (void)updateSoftRouterVmStatus:(BOOL)started {
    SoftRouterOperateStatus operateStatus = [CLCSoftRouterManager instance].operateStatus;
    if (operateStatus == SoftRouterOperateStatusStarting) {
        [self.vmStatusLabel setStringValue:@"启动中..."];
        [self.switchVmButton setTitle:@"启动中"];
        [self.switchVmButton setEnabled:NO];
    } else if (operateStatus == SoftRouterOperateStatusStopping) {
        [self.vmStatusLabel setStringValue:@"停止中..."];
        [self.switchVmButton setTitle:@"停止中"];
        [self.switchVmButton setEnabled:NO];
    } else if (operateStatus == SoftRouterOperateStatusComputing) {
        //        [self.switchVmButton setTitle:@"操作中..."];
        [self.switchVmButton setEnabled:NO];
    } else {
        if (started) {
            [self.vmStatusLabel setStringValue:@"已启动"];
            [self.switchVmButton setTitle:@"停止"];
        } else {
            [self.vmStatusLabel setStringValue:@"已停止"];
            [self.switchVmButton setTitle:@"启动"];
        }
        [self.switchVmButton setEnabled:YES];
    }
}

- (void)monitorToUpdateAllViews {
    [self monitorToUpdateSoftRouterVmStatus];
    RACSignal *timeSignal = [self timeSignal:2];
    [self monitorToUpdateUsbDnsStatus:timeSignal];
    [self monitorToUpdateWifiDnsStatus:timeSignal];
}

- (void)monitorToUpdateWifiDnsStatus:(RACSignal *)timeSignal {
    self.updateWifiDnsStatusDisposable = [[timeSignal map:^id(id value) {
      NSString *wifiDns = [CLCMiscUtils getInterfaceDns:INTERFACE_WIFI];
      BOOL isInterfaceEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_WIFI];
      return [RACTwoTuple pack:@(isInterfaceEnabled):wifiDns];
    }] subscribeNext:^(RACTwoTuple *x) {
      NSNumber *enabled = x.first;
      [self updateNetDnsStatus:self.wifiDnsStatusLabel isEnabled:enabled.boolValue dnsStr:x.second];
    }];
}
- (void)monitorToUpdateUsbDnsStatus:(RACSignal *)timeSignal {
    self.updateUsbDnsStatusDisposable = [[timeSignal map:^id(id value) {
      NSString *usbDns = [CLCMiscUtils getInterfaceDns:INTERFACE_USB];
      BOOL isInterfaceEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_USB];
      return [RACTwoTuple pack:@(isInterfaceEnabled):usbDns];
    }] subscribeNext:^(RACTwoTuple *x) {
      NSNumber *enabled = x.first;
      [self updateNetDnsStatus:self.usbDnsStatusLabel isEnabled:enabled.boolValue dnsStr:x.second];
    }];
}
- (void)monitorToUpdateSoftRouterVmStatus {
    RACSignal *timeSignal = [self timeSignal:5];
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    self.updateSoftRouterVmStatusDisposable = [[[[[RACSignal combineLatest:@[ timeSignal, opStatusSignal ]]
        deliverOn:[RACScheduler scheduler]] map:^id(RACTuple *value) {
      BOOL softRouterStarted = [CLCMiscUtils isSoftRouterStarted];
      NSString *wifiDns = [CLCMiscUtils getInterfaceDns:INTERFACE_WIFI];
      return @(softRouterStarted);
    }] deliverOnMainThread] subscribeNext:^(NSNumber *value) {
      [self updateSoftRouterVmStatus:(value.boolValue)];
    }];
}

- (void)updateNetDnsStatus:(NSTextField *)textField isEnabled:(BOOL)isEnabled dnsStr:(NSString *)dnsStr {
    if (!isEnabled) {
        [textField setStringValue:@"Interface Not Connected"];
    } else {
        if ([dnsStr containsString:@"192.168.100.1"]) {
            [textField setStringValue:@"Interface Not Connected"];
        } else if ([dnsStr containsString:@"There aren't any DNS Servers set on"]) {
            [textField setStringValue:@"Default"];
        } else {
            [textField setStringValue:[NSString stringWithFormat:@"%@", dnsStr]];
        }
    }
}

- (void)stopUpdateTask {
    if (self.updateSoftRouterVmStatusDisposable != nil) {
        [self.updateSoftRouterVmStatusDisposable dispose];
        self.updateSoftRouterVmStatusDisposable = nil;
    }
    if (self.updateWifiDnsStatusDisposable != nil) {
        [self.updateWifiDnsStatusDisposable dispose];
        self.updateWifiDnsStatusDisposable = nil;
    }
    if (self.updateUsbDnsStatusDisposable != nil) {
        [self.updateUsbDnsStatusDisposable dispose];
        self.updateUsbDnsStatusDisposable = nil;
    }
}

- (RACSignal<NSDate *> *)timeSignal:(NSInteger)timeInterval {
    RACSignal *coldSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      [subscriber sendNext:[NSDate date]];
      [subscriber sendCompleted];
      return nil;
    }];
    RACSignal *hotSignal = [RACSignal interval:timeInterval onScheduler:[RACScheduler scheduler] withLeeway:0];
    return [RACSignal merge:@[ coldSignal, hotSignal ]];
}

@end
