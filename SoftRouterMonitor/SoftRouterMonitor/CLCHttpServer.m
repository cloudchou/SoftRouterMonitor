//
//  CLCHttpServer.m
//  SoftRouterMonitor
//
//  Created by CloudChou on 2018/9/1.
//  Copyright © 2018 CloudChou. All rights reserved.
//

#import "CLCHttpServer.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataResponse.h"

@interface CLCHttpServer ()
@property(nonatomic, strong)  GCDWebServer* webServer;
@end

@implementation CLCHttpServer

+ (instancetype)instance {
    static CLCHttpServer *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [CLCHttpServer new];
    });
    return instance;
}

- (GCDWebServer *)webServer {
    if (!_webServer) {
         // Create server
         _webServer = [[GCDWebServer alloc] init];
    }
    return _webServer;
}


- (void)startWork {
  // Start server on port 8080
    [self addHandlers];
  [self.webServer startWithPort:8716 bonjourName:nil];
   DDLogDebug(@"=======> server listen on 8080");
}

- (void)addHandlers {
    // Add a handler to respond to GET requests on any URL
   [self.webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                  return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
                              }];
    [self.webServer addHandlerForMethod: @"GET"
                     path: @"/gateway" 
                     requestClass:[GCDWebServerRequest class]
                     processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
        return [GCDWebServerDataResponse responseWithHTML:@"<html><body><p>Hello World</p></body></html>"];
                     }];
}

@end
