
#import "CLCMiscUtils.h"
#import "CLCShellUtils.h"
#import "CLCSoftRouterManager.h"
#import "CLCStatusMenuController.h"

@interface CLCStatusMenuController ()

@property(nonatomic, strong) NSWindowController *mainWindowController;

@end

@implementation CLCStatusMenuController {
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
    [self.mainWindowController showWindow:self];
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
    NSString *url = @"http://192.168.100.1/cgi-bin/luci//admin/vpn/shadowsocks";
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
          if ([dns containsString:@"192.168.100.1"]) {
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
