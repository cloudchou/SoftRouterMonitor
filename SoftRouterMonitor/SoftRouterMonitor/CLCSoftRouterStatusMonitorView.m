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
@property(nonatomic, strong) NSMutableArray<RACDisposable *> *updateNetOkStatusDisposableArr;
@property(nonatomic, weak) RACDisposable *updateSwitchNetButtonStatusDisposable;

@property(nonatomic, assign) BOOL computingVmForeignNetStatus;
@property(nonatomic, assign) BOOL computingVmHomeNetStatus;
@property(nonatomic, assign) BOOL computingForeignNetStatus;
@property(nonatomic, assign) BOOL computingHomeNetStatus;
@end

@implementation CLCSoftRouterStatusMonitorView

- (NSMutableArray *)updateNetOkStatusDisposableArr {
    if (!_updateNetOkStatusDisposableArr) {
        _updateNetOkStatusDisposableArr = [[NSMutableArray alloc] init];
    }
    return _updateNetOkStatusDisposableArr;
}

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
    [self monitorToUpdateNetStatus];
    [self monitorToUpdateSwitchNetButtonStatus];
}

- (void)monitorToUpdateNetStatus {
    // 判断网络是否连接上的超时时间时30s
    RACSignal<NSDate *> *timeSignal = [self timeSignal:60];
    RACSignal *vmStatusSignal = [[[RACObserve([CLCSoftRouterManager instance], operateStatus)
        deliverOn:[RACScheduler scheduler]] map:^id(id value) {
      BOOL softRouterStarted = [CLCMiscUtils isSoftRouterStarted];
      return @(softRouterStarted);
    }] distinctUntilChanged];

    [self monitorVmForeignNetStatus:vmStatusSignal timeSignal:timeSignal];
    [self monitorVmHomeNetStatus:vmStatusSignal timeSignal:timeSignal];

    RACSignal *routerChangeSignal = [[[RACObserve([CLCSoftRouterManager instance], operateStatus)
        deliverOn:[RACScheduler scheduler]] map:^id(id value) {
      BOOL softRouterStarted = [CLCMiscUtils isSoftRouterDefaultGateWay];
      return @(softRouterStarted);
    }] distinctUntilChanged];
    RACSignal<RACTuple *> *changeSignal = [RACSignal combineLatest:@[vmStatusSignal,routerChangeSignal,timeSignal]];
    [self monitorForeignNetStatus:changeSignal];
    [self monitorHomeNetStatus:changeSignal];

}

- (void)monitorVmForeignNetStatus:(RACSignal *)vmStatusSignal timeSignal:(RACSignal<NSDate *> *)timeSignal {
    RACSignal *vmNetStatusSignal = [[[timeSignal doNext:^(NSDate *x) {
      self.computingVmForeignNetStatus = YES;
    }] map:^id(NSDate *value) {
      BOOL isSoftRouterVmForeignNetOk = [CLCMiscUtils isSoftRouterVmForeignNetOkay];
      return @(isSoftRouterVmForeignNetOk);
    }] doNext:^(id x) {
      self.computingVmForeignNetStatus = NO;
    }];
    RACSignal *computingSignal = RACObserve(self, computingVmForeignNetStatus);
    RACDisposable *disposable =
        [[RACSignal combineLatest:@[ vmStatusSignal, computingSignal, vmNetStatusSignal ]] subscribeNext:^(RACTuple *x) {
          NSNumber *vmStatus = x.first;
          NSNumber *computingStatus = x.second;
          NSNumber *vmNetStatus = x.third;
          if (!vmStatus.boolValue) {
              [self.softRouterForeignNetStatusLabel setStringValue:@"软路由未启动"];
          } else {
              if (computingStatus.boolValue) {
                  [self.softRouterForeignNetStatusLabel setStringValue:@"计算中..."];
              } else {
                  if (vmNetStatus.boolValue) {
                      [self.softRouterForeignNetStatusLabel setStringValue:@"连接正常"];
                  } else {
                      [self.softRouterForeignNetStatusLabel setStringValue:@"连接失败"];
                  }
              }
          }
        }];
    [self.updateNetOkStatusDisposableArr addObject:disposable];
}

- (void)monitorVmHomeNetStatus:(RACSignal *)vmStatusSignal timeSignal:(RACSignal<NSDate *> *)timeSignal {
    RACSignal *vmNetStatusSignal = [[[timeSignal doNext:^(NSDate *x) {
      self.computingVmHomeNetStatus = YES;
    }] map:^id(NSDate *value) {
      BOOL isNetOk = [CLCMiscUtils isSoftRouterVmHomeNetOkay];
      return @(isNetOk);
    }] doNext:^(id x) {
      self.computingVmHomeNetStatus = NO;
    }];
    RACSignal *computingSignal = RACObserve(self, computingVmHomeNetStatus);
    RACDisposable *disposable =
        [[RACSignal combineLatest:@[ vmStatusSignal, computingSignal, vmNetStatusSignal ]] subscribeNext:^(RACTuple *x) {
          NSNumber *vmStatus = x.first;
          NSNumber *computingStatus = x.second;
          NSNumber *vmNetStatus = x.third;
          if (!vmStatus.boolValue) {
              [self.softRouterHomeNetStatusLabel setStringValue:@"软路由未启动"];
          } else {
              if (computingStatus.boolValue) {
                  [self.softRouterHomeNetStatusLabel setStringValue:@"计算中..."];
              } else {
                  if (vmNetStatus.boolValue) {
                      [self.softRouterHomeNetStatusLabel setStringValue:@"连接正常"];
                  } else {
                      [self.softRouterHomeNetStatusLabel setStringValue:@"连接失败"];
                  }
              }
          }
        }];
    [self.updateNetOkStatusDisposableArr addObject:disposable];
}

- (void)monitorForeignNetStatus:(RACSignal *)changeSignal{
    RACSignal *netStatusSignal = [[[changeSignal doNext:^(id x) {
      self.computingForeignNetStatus = YES;
    }] map:^id(id value) {
      BOOL isNetOk = [CLCMiscUtils isForeignNetOkay];
      return @(isNetOk);
    }] doNext:^(id x) {
      self.computingForeignNetStatus = NO;
    }];
    RACSignal *computingSignal = RACObserve(self, computingForeignNetStatus);
    RACDisposable *disposable =
        [[RACSignal combineLatest:@[computingSignal, netStatusSignal ]] subscribeNext:^(RACTuple *x) {
          NSNumber *computingStatus = x.first;
          NSNumber *netStatus = x.second;
          if (computingStatus.boolValue) {
              [self.foreignNetStatusLabel setStringValue:@"计算中..."];
          } else {
              if (netStatus.boolValue) {
                  [self.foreignNetStatusLabel setStringValue:@"连接正常"];
              } else {
                  [self.foreignNetStatusLabel setStringValue:@"连接失败"];
              }
          }
        }];
    [self.updateNetOkStatusDisposableArr addObject:disposable];
}

- (void)monitorHomeNetStatus:(RACSignal *)changeSignal{
    RACSignal *netStatusSignal = [[[changeSignal doNext:^(id x) {
      self.computingHomeNetStatus = YES;
    }] map:^id(id value) {
      BOOL isNetOk = [CLCMiscUtils isHomeNetOkay];
      return @(isNetOk);
    }] doNext:^(id x) {
      self.computingHomeNetStatus = NO;
    }];
    RACSignal *computingSignal = RACObserve(self, computingHomeNetStatus);
    RACDisposable *disposable =
        [[RACSignal combineLatest:@[computingSignal, netStatusSignal ]] subscribeNext:^(RACTuple *x) {
          NSNumber *computingStatus = x.first;
          NSNumber *netStatus = x.second;
          if (computingStatus.boolValue) {
              [self.homeNetStatusLabel setStringValue:@"计算中..."];
          } else {
              if (netStatus.boolValue) {
                  [self.homeNetStatusLabel setStringValue:@"连接正常"];
              } else {
                  [self.homeNetStatusLabel setStringValue:@"连接失败"];
              }
          }
        }];
    [self.updateNetOkStatusDisposableArr addObject:disposable];
}


- (void)monitorToUpdateWifiDnsStatus {
    RACSignal<NSDate *> *timeSignal = [self timeSignal:5];
    //    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *opStatusSignal =
        [RACObserve([CLCSoftRouterManager instance], operateStatus) deliverOn:[RACScheduler scheduler]];
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
    //    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *opStatusSignal =
        [RACObserve([CLCSoftRouterManager instance], operateStatus) deliverOn:[RACScheduler scheduler]];
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
    //    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *opStatusSignal =
        [RACObserve([CLCSoftRouterManager instance], operateStatus) deliverOn:[RACScheduler scheduler]];
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
    //    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *opStatusSignal =
        [RACObserve([CLCSoftRouterManager instance], operateStatus) deliverOn:[RACScheduler scheduler]];
    self.updateSoftRouterVmStatusDisposable = [[[[[RACSignal combineLatest:@[ timeSignal, opStatusSignal ]]
        deliverOn:[RACScheduler scheduler]] map:^id(RACTuple *value) {
      BOOL softRouterStarted = [CLCMiscUtils isSoftRouterStarted];
      return @(softRouterStarted);
    }] deliverOnMainThread] subscribeNext:^(NSNumber *value) {
      [self updateSoftRouterVmStatus:(value.boolValue)];
    }];
}

- (void)monitorToUpdateSwitchNetButtonStatus {
    //    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    RACSignal *opStatusSignal =
        [RACObserve([CLCSoftRouterManager instance], operateStatus) deliverOn:[RACScheduler scheduler]];
    self.updateSwitchNetButtonStatusDisposable = [[opStatusSignal deliverOnMainThread] subscribeNext:^(NSNumber *x) {
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
    if (self.updateSwitchNetButtonStatusDisposable != nil) {
        [self.updateSwitchNetButtonStatusDisposable dispose];
        self.updateSwitchNetButtonStatusDisposable = nil;
    }
    for (RACDisposable *updateNetOkStatusDisposable in self.updateNetOkStatusDisposableArr) {
        [updateNetOkStatusDisposable dispose];
    }
    [self.updateNetOkStatusDisposableArr removeAllObjects];
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
