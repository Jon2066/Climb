//
//  PacketTunnelProvider.m
//  PacketTunnel
//
//  Created by Jonathan on 2020/4/17.
//  Copyright © 2020 JN. All rights reserved.
//

#import "PacketTunnelProvider.h"
#import "JNTunnelModel.h"
#import "JNNetworkSetting.h"
#import "JNLocalServer.h"

@interface PacketTunnelProvider ()
@property (nonatomic, strong) JNTunnelModel *currentTunnelModel;
@property (nonatomic, strong) JNLocalServer *localServer;
@end

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    // Add code here to start the process of connecting the tunnel.
    
    //测试代码 休眠8秒以便这个方法Debug断点可以调试
//    sleep(8);
    
    NSDictionary *json =  ((NETunnelProviderProtocol *)self.protocolConfiguration).providerConfiguration;
    self.currentTunnelModel = [JNTunnelModel yy_modelWithJSON:json];
    
    NETunnelNetworkSettings *networkSettings = [JNNetworkSetting networkSettings];
    
    __weak typeof(self) weakSelf = self;
    [self setTunnelNetworkSettings:networkSettings completionHandler:^(NSError * _Nullable error) {
        if (error) {
            // 设置失败
            completionHandler(error);
        }
        else{
            [weakSelf startLocalServer];
            // 开启成功
            completionHandler(nil);
        }
    }];
    
}


- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    // Add code here to start the process of stopping the tunnel.
    completionHandler();
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    // Add code here to handle the message.
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    // Add code here to get ready to sleep.
    completionHandler();
}

- (void)wake {
    // Add code here to wake up.
}

#pragma mark - read packet -
- (void)startLocalServer
{
    [self.localServer start];
}

- (void)stopLocalServer
{
    [self.localServer stop];
}

- (JNLocalServer *)localServer
{
    if (!_localServer) {
        _localServer = [[JNLocalServer alloc] initWithTunnelModel:self.currentTunnelModel];
    }
    return _localServer;
}

@end
