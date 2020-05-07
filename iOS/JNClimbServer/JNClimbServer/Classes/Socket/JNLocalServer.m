//
//  JNClimbWebSocket.m
//  AFNetworking
//
//  Created by Jonathan on 2020/4/18.
//

#import "JNLocalServer.h"
#import "GCDAsyncSocket.h"
#import "JNNetworkSetting.h"
#import "JNSocketConnect.h"
#import "GCDAsyncSocket+KVC.h"

@interface JNLocalServer ()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
@property (nonatomic, strong) dispatch_queue_t localSocketQueue;
@property (nonatomic, strong) dispatch_queue_t connectQueue;
@property (nonatomic, strong) JNTunnelModel *tunnelModel;
@end

@implementation JNLocalServer

- (void)dealloc
{
    
}

- (instancetype)initWithTunnelModel:(JNTunnelModel *)model
{
    self = [super init];
    if (self) {
        _tunnelModel = model;
        [self  setupSocket];
    }
    return self;
}

- (void)setupSocket
{
    self.connectQueue = dispatch_queue_create("jn.wang.wconnect.connect", DISPATCH_QUEUE_SERIAL);
    self.localSocketQueue = dispatch_queue_create("jn.wang.wconnect.socket", DISPATCH_QUEUE_SERIAL);
    self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.localSocketQueue socketQueue:self.localSocketQueue];
}


- (void)start
{
    NSError *error = nil;
    // 服务端 用于接收 JNNetworkSetting中httpProxyServer发来的数据
    BOOL accept = [self.listenSocket acceptOnInterface:@"localhost" port:[JNNetworkSetting localProxyServerPort] error:&error];
}

- (void)stop
{
    [self.listenSocket disconnect];
}

#pragma mark - socket delegate -

- (dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock
{
    return nil;
}
// 拦截到本机发出到的请求
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    //创建一个代理用于转发
    JNSocketConnect *connect = [[JNSocketConnect alloc] init];
    connect.tunnelModel = self.tunnelModel;
    connect.clientSocket = newSocket;
    connect.connectQueue = self.connectQueue;
//    [connect startRemoteConnect];
    ///建立一个循环引用 阻止释放
    [newSocket retainConnect:connect];
    
    [newSocket readDataWithTimeout:-1 tag:0];
}

// 连接断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (sock != self.listenSocket) {
        // 打破循环引用 释放connect和socket
        [sock removeConnect];
    }
}

//接收
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    if (sock != self.listenSocket) {
        [[sock getConnect] writeData:data];
        //连接成功或者收到消息，必须开始read，否则将无法收到消息
        [sock readDataWithTimeout:-1 tag:1];
    }
    
}

//消息发送成功
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{

}

@end
