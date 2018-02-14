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
@property(nonatomic, weak) RACDisposable *updateDisposable;
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
    if(operateStatus==SoftRouterOperateStatusStarting){
        [self.vmStatusLabel setStringValue:@"启动中..."];
        [self.switchVmButton setTitle:@"启动中"];
        [self.switchVmButton setEnabled:NO];
    }else if(operateStatus==SoftRouterOperateStatusStopping){
        [self.vmStatusLabel setStringValue:@"停止中..."];
        [self.switchVmButton setTitle:@"停止中"];
        [self.switchVmButton setEnabled:NO];
    }else if(operateStatus==SoftRouterOperateStatusComputing){
//        [self.switchVmButton setTitle:@"操作中..."];
        [self.switchVmButton setEnabled:NO];
    }else{
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
    RACSignal *timeSignal = [self timeSignal];
    RACSignal *opStatusSignal = RACObserve([CLCSoftRouterManager instance], operateStatus);
    self.updateDisposable = [[[[[RACSignal combineLatest:@[ timeSignal, opStatusSignal ]]
        deliverOn:[RACScheduler scheduler]] map:^id(RACTuple *value) {
      BOOL softRouterStarted = [CLCMiscUtils isSoftRouterStarted];
      return @(softRouterStarted);
    }] deliverOnMainThread] subscribeNext:^(NSNumber *value) {
      [self updateSoftRouterVmStatus:value.boolValue];
    }];
}

- (void)stopUpdateTask {
    if (self.updateDisposable != nil) {
        [self.updateDisposable dispose];
        self.updateDisposable = nil;
    }
}

- (RACSignal<NSDate *> *)timeSignal {
    RACSignal *coldSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      [subscriber sendNext:[NSDate date]];
      [subscriber sendCompleted];
      return nil;
    }];
    RACSignal *hotSignal = [RACSignal interval:5 onScheduler:[RACScheduler scheduler] withLeeway:0];
    return [RACSignal merge:@[ coldSignal, hotSignal ]];
}

@end
