
#import "CLCMiscUtils.h"
#import "CLCShellUtils.h"
#import "CLCSoftRouterManager.h"
#import "CLCStatusMenuController.h"
#import "CLCViewHolder.h"
#import "ReactiveObjC/ReactiveObjC.h"

@interface CLCStatusMenuController ()

@property(nonatomic, strong) NSWindowController *mainWindowController;
@property(nonatomic, strong) RACDisposable *statusIconAnimDisposable;

@end

@implementation CLCStatusMenuController {
    BOOL iconAnimChange;
}

- (IBAction)quitApp:(id)sender {
    [NSApplication.sharedApplication terminate:self];
}

- (IBAction)openRunLog:(id)sender {
    NSArray<NSString *> *logFilePaths = [DDFileLogger new].logFileManager.sortedLogFilePaths;
    NSString *logDir = [logFilePaths[0] stringByDeletingLastPathComponent];
    [[NSWorkspace sharedWorkspace] openFile:logDir];
    //    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (IBAction)gotoSoftRouterStatusMonitorView:(id)sender {
    //    [self.mainWindowController close];
    if (![self.mainWindowController.window isVisible]) {
        [self.mainWindowController showWindow:self];
        //        [self.mainWindowController.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
        [NSApp activateIgnoringOtherApps:YES];
    } else {
        //        [self.mainWindowController.window orderWindow:NSWindowAbove relativeTo:0];
        [self.mainWindowController.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

- (IBAction)switchToSoftRouter:(id)sender {
    [[CLCSoftRouterManager instance] connectNetToSoftRouter];
}

- (IBAction)switchToRealRouter:(id)sender {
    [[CLCSoftRouterManager instance] connectNetToRealRouter];
}

- (NSWindowController *)mainWindowController {
    if (_mainWindowController == nil) {
        NSStoryboard *sb = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
        _mainWindowController = [sb instantiateControllerWithIdentifier:@"MainWindow"];
    }
    return _mainWindowController;
}

- (IBAction)openRouterKoolSS:(id)sender {
    NSString *url = @"http://openwrt/cgi-bin/luci//admin/koolsoft#/Module_koolss.asp";
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    self.statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
    NSImage *image = [NSImage imageNamed:@"StatusIcon"];
    [self.statusItem setImage:image];
    [self.statusItem setHighlightMode:YES];
    self.statusItem.target = self;
    self.statusItem.action = @selector(onStatusItemClicked);
    [self monitorOperateStatusToChangeIcon];
    [[CLCViewHolder instance] setMenuController:self];
}

- (void)monitorOperateStatusToChangeIcon {
    [[[[RACObserve([CLCSoftRouterManager instance], operateStatus) map:^id(NSNumber *value) {
      return @(value.integerValue == SoftRouterOperateStatusNone);
    }] distinctUntilChanged] deliverOnMainThread] subscribeNext:^(NSNumber *x) {
      if (x.boolValue) {
          DDLogDebug(@"vm not operating no need to display status icon anim");
          [self stopStatusIconAnim];
          NSImage *image = [NSImage imageNamed:@"StatusIcon"];
          [self.statusItem setImage:image];
      } else {
          DDLogDebug(@"vm operating need to display status icon anim");
          [self displayStatusIconAnim];
      }
    }];
}

- (void)stopStatusIconAnim {
    if (self.statusIconAnimDisposable) {
        [self.statusIconAnimDisposable dispose];
        self.statusIconAnimDisposable = nil;
    }
}

- (void)displayStatusIconAnim {
    self.statusIconAnimDisposable =
        [[RACSignal interval:0.8 onScheduler:[RACScheduler mainThreadScheduler]] subscribeNext:^(NSDate *x) {
          if (iconAnimChange) {
              NSImage *image = [NSImage imageNamed:@"StatusIcon"];
              [self.statusItem setImage:image];
          } else {
              NSImage *image = [NSImage imageNamed:@"StatusIconChanging"];
              [self.statusItem setImage:image];
          }
          iconAnimChange = !iconAnimChange;
        }];
}

- (void)onStatusItemClicked {
    NSLog(@"status item clicked");
    [self updateSoftRouterVmStatus];
    // USB 网络的dns设置
    NSMenuItem *usbNetDnsMenuItem = [self.statusBarMenu itemAtIndex:2];
    [self updateNetDnsStatus:usbNetDnsMenuItem tag:@"USBNetDns" interfaceName:INTERFACE_USB];
    // Wifi 的 dns 设置
    NSMenuItem *wifiNetDnsMenuItem = [self.statusBarMenu itemAtIndex:1];
    [self updateNetDnsStatus:wifiNetDnsMenuItem tag:@"WIFINetDns" interfaceName:INTERFACE_WIFI];
    //默认网关
    [self updateDefaultGatewayStatus];
    [self.statusItem popUpStatusItemMenu:self.statusBarMenu];
    //    [self.statusItem setMenu:self.statusBarMenu];
}

- (void)updateDefaultGatewayStatus {
    NSMenuItem *defaultGatewayMenuItem = [self.statusBarMenu itemAtIndex:3];
    [defaultGatewayMenuItem setTitle:@"DefaultGateway:computing..."];
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(bgQueue, ^{
      NSString *output = [CLCMiscUtils getDefaultGateway];
      dispatch_sync(dispatch_get_main_queue(), ^{
        if ([output containsString:@"192.168.100.1"]) {
            [defaultGatewayMenuItem setTitle:@"DefaultGateway:SoftRouter"];
        } else {
            [defaultGatewayMenuItem setTitle:[NSString stringWithFormat:@"DefaultGateway:%@", output]];
        }
      });
    });
}

- (void)updateNetDnsStatus:(NSMenuItem *)menuItem tag:(NSString *)tag interfaceName:(NSString *)interfaceName {
    [menuItem setTitle:[NSString stringWithFormat:@"%@:computing", tag]];
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(bgQueue, ^{
      NSString *newStatus;
      if (![CLCMiscUtils isInterfaceEnabled:interfaceName]) {
          newStatus = [NSString stringWithFormat:@"%@:%@ Not Connected", tag, tag];
      } else {
          NSString *dns = [CLCMiscUtils getInterfaceDns:interfaceName];
          if ([dns isEqualToString:@"192.168.100.1"]) {
              newStatus = [NSString stringWithFormat:@"%@:SoftRouter", tag];
          } else if ([dns containsString:@"There aren't any DNS Servers set on"]) {
              newStatus = [NSString stringWithFormat:@"%@:Default", tag];
          } else {
              newStatus = [NSString stringWithFormat:@"%@:%@", tag, dns];
          }
      }
      dispatch_sync(dispatch_get_main_queue(), ^{
        [menuItem setTitle:newStatus];
      });
    });
}

- (void)updateSoftRouterVmStatus {
    NSMenuItem *softRouterVmMenuItem = [self.statusBarMenu itemAtIndex:0];
    [softRouterVmMenuItem setTitle:@"SoftRouterVM:computing..."];
    dispatch_queue_t bgQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(bgQueue, ^{
      BOOL started = [CLCMiscUtils isSoftRouterStarted];
      dispatch_sync(dispatch_get_main_queue(), ^{
        if (started) {
            [softRouterVmMenuItem setTitle:@"SoftRouterVM:Started"];
        } else {
            [softRouterVmMenuItem setTitle:@"SoftRouterVM:Stoped"];
        }
      });
    });
}

@end
