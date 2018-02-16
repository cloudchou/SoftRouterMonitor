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
@property(nonatomic, weak) IBOutlet NSTextField *homeNetStatusLabel;
@property(nonatomic, weak) IBOutlet NSTextField *foreignNetStatusLabel;
@property(nonatomic, weak) IBOutlet NSButtonCell *switchVmButton;
@property(weak) IBOutlet NSButton *switchSoftRouterVmButton;
@property(weak) IBOutlet NSButton *switchRealRouterButton;

@property(nonatomic, weak) RACDisposable *updateSoftRouterVmStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateUsbDnsStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateWifiDnsStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateDefaultGatewayStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateNetOkStatusDisposable;
@property(nonatomic, weak) RACDisposable *updateSwitchNetButtonStatusDisposable ;
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
    [self.homeNetStatusLabel setStringValue:@"计算中..."];
    [self.foreignNetStatusLabel setStringValue:@"计算中..."];
}

- (IBAction)onVmStatusSwitchClicked:(id)sender {
    [[CLCSoftRouterManager instance] toggleSoftRouterVm];
}

- (IBAction)onSwitchNetToSoftRouter:(id)sender {
    [[CLCSoftRouterManager instance] connectNetToSoftRouter];
}

- (IBAction)onSwitchNetToRealRouter:(id)sender {
    [[CLCSoftRouterManager instance] connectNetToRealRouter];
}
- (IBAction)onOpenSoftRouterVmVpnSetting:(id)sender {
    NSString *url = @"http://192.168.100.1/cgi-bin/luci//admin/vpn/shadowsocks";
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
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
    [self monitorToUpdateUsbDnsStatus];
    [self monitorToUpdateWifiDnsStatus];
    [self monitorToUpdateDefaultGatewayStatus];
    [self monitorToUpdateSoftRouterVmForeignNetStatus];
    [self monitorToUpdateSwitchNetButtonStatus];
}

- (void)monitorToUpdateSoftRouterVmForeignNetStatus {
    RACSignal<NSDate *> *timeSignal = [self timeSignal:3];
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *changeSignal = [RACSignal combineLatest:@[ opStatusSignal, timeSignal ]];
    RACSignal *vmForeignSignal = [[[changeSignal map:^id(id value) {
      if ([CLCMiscUtils isSoftRouterStarted]) {
          BOOL isSoftRouterVmForeignNetOk = [CLCMiscUtils isSoftRouterVmForeignNetOkay];
          return [RACTwoTuple pack:@(YES):@(isSoftRouterVmForeignNetOk)];
      } else {
          return [RACTwoTuple pack:@(NO):@(NO)];
      }
    }] deliverOnMainThread] doNext:^(RACTwoTuple *x) {
      NSNumber *value1 = x.first;
      NSNumber *value2 = x.second;
      if (!value1.boolValue) {
          [self.softRouterForeignNetStatusLabel setStringValue:@"软路由未启动"];
      } else {
          if (value2.boolValue) {
              [self.softRouterForeignNetStatusLabel setStringValue:@"连接正常"];
          } else {
              [self.softRouterForeignNetStatusLabel setStringValue:@"连接失败"];
          }
      }
    }];
    RACSignal *vmHomeSignal = [[[changeSignal map:^id(id value) {
      if ([CLCMiscUtils isSoftRouterStarted]) {
          BOOL isSoftRouterVmHomeNetOk = [CLCMiscUtils isSoftRouterVmHomeNetOkay];
          return [RACTwoTuple pack:@(YES):@(isSoftRouterVmHomeNetOk)];
      } else {
          return [RACTwoTuple pack:@(NO):@(NO)];
      }
    }] deliverOnMainThread] doNext:^(RACTwoTuple *x) {
      NSNumber *value1 = x.first;
      NSNumber *value2 = x.second;
      if (!value1.boolValue) {
          [self.softRouterHomeNetStatusLabel setStringValue:@"软路由未启动"];
      } else {
          if (value2.boolValue) {
              [self.softRouterHomeNetStatusLabel setStringValue:@"连接正常"];
          } else {
              [self.softRouterHomeNetStatusLabel setStringValue:@"连接失败"];
          }
      }
    }];
    RACSignal *foreignSignal = [[[changeSignal map:^id(id value) {
      BOOL isForeignNetOk = [CLCMiscUtils isForeignNetOkay];
      return @(isForeignNetOk);
    }] deliverOnMainThread] doNext:^(NSNumber *x) {
      if (x.boolValue) {
          [self.foreignNetStatusLabel setStringValue:@"连接正常"];
      } else {
          [self.foreignNetStatusLabel setStringValue:@"连接失败"];
      }
    }];
    RACSignal *homeSignal = [[[changeSignal map:^id(id value) {
      BOOL isHomeNetOk = [CLCMiscUtils isHomeNetOkay];
      return @(isHomeNetOk);
    }] deliverOnMainThread] doNext:^(NSNumber *x) {
      if (x.boolValue) {
          [self.homeNetStatusLabel setStringValue:@"连接正常"];
      } else {
          [self.homeNetStatusLabel setStringValue:@"连接失败"];
      }
    }];
    self.updateNetOkStatusDisposable = [[RACSignal
        combineLatest:@[ vmForeignSignal, vmHomeSignal, foreignSignal, homeSignal ]] subscribeNext:^(RACTuple *x) {
      DDLogVerbose(@"net status update");
    }];
}

- (void)monitorToUpdateWifiDnsStatus {
    RACSignal<NSDate *> *timeSignal = [self timeSignal:5];
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *changeSignal = [RACSignal combineLatest:@[ opStatusSignal, timeSignal ]];
    self.updateWifiDnsStatusDisposable = [[changeSignal map:^id(id value) {
      NSString *wifiDns = [CLCMiscUtils getInterfaceDns:INTERFACE_WIFI];
      BOOL isInterfaceEnabled = [CLCMiscUtils isInterfaceEnabled:INTERFACE_WIFI];
      return [RACTwoTuple pack:@(isInterfaceEnabled):wifiDns];
    }] subscribeNext:^(RACTwoTuple *x) {
      NSNumber *enabled = x.first;
      [self updateNetDnsStatus:self.wifiDnsStatusLabel isEnabled:enabled.boolValue dnsStr:x.second];
    }];
}

- (void)monitorToUpdateDefaultGatewayStatus {
    RACSignal<NSDate *> *timeSignal = [self timeSignal:5];
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *changeSignal = [RACSignal combineLatest:@[ opStatusSignal, timeSignal ]];
    self.updateDefaultGatewayStatusDisposable = [[changeSignal map:^id(id value) {
      NSString *output = [CLCMiscUtils getDefaultGateway];
      return output;
    }] subscribeNext:^(NSString *x) {
      if ([x containsString:@"192.168.100.1"]) {
          [self.defaultGatewayStatusLabel setStringValue:@"SoftRouter"];
      } else {
          [self.defaultGatewayStatusLabel setStringValue:x];
      }
    }];
}

- (void)monitorToUpdateUsbDnsStatus {
    RACSignal<NSDate *> *timeSignal = [self timeSignal:5];
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *changeSignal = [RACSignal combineLatest:@[ opStatusSignal, timeSignal ]];
    self.updateUsbDnsStatusDisposable = [[changeSignal map:^id(id value) {
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
      return @(softRouterStarted);
    }] deliverOnMainThread] subscribeNext:^(NSNumber *value) {
      [self updateSoftRouterVmStatus:(value.boolValue)];
    }];
}

- (void)monitorToUpdateSwitchNetButtonStatus{
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    self.updateSwitchNetButtonStatusDisposable =
        [[opStatusSignal deliverOnMainThread] subscribeNext:^(NSNumber *x) {
          if (x.integerValue == SoftRouterOperateStatusNone) {
              self.switchSoftRouterVmButton.enabled = YES;
              self.switchRealRouterButton.enabled = YES;
          } else {
              self.switchSoftRouterVmButton.enabled = NO;
              self.switchRealRouterButton.enabled = NO;
          }
        }];
}

- (void)updateNetDnsStatus:(NSTextField *)textField isEnabled:(BOOL)isEnabled dnsStr:(NSString *)dnsStr {
    if (!isEnabled) {
        [textField setStringValue:@"Interface Not Connected"];
    } else {
        if ([dnsStr containsString:@"192.168.100.1"]) {
            [textField setStringValue:@"Soft Router"];
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
    if (self.updateDefaultGatewayStatusDisposable != nil) {
        [self.updateDefaultGatewayStatusDisposable dispose];
        self.updateDefaultGatewayStatusDisposable = nil;
    }
    if (self.updateNetOkStatusDisposable != nil) {
        [self.updateNetOkStatusDisposable dispose];
        self.updateNetOkStatusDisposable = nil;
    }
    if(self.updateSwitchNetButtonStatusDisposable!=nil){
        [self.updateSwitchNetButtonStatusDisposable dispose];
        self.updateSwitchNetButtonStatusDisposable = nil;
    }
}

- (RACSignal<NSDate *> *)timeSignal:(NSInteger)timeInterval {
    RACSignal *coldSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      [[RACScheduler scheduler] schedule:^{
        [subscriber sendNext:[NSDate date]];
        [subscriber sendCompleted];
      }];
      return nil;
    }];
    RACSignal *hotSignal = [RACSignal interval:timeInterval onScheduler:[RACScheduler scheduler] withLeeway:0];
    return [RACSignal merge:@[ coldSignal, hotSignal ]];
}

@end
