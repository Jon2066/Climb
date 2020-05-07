//
//  JNRemoteSocket.m
//  AFNetworking
//
//  Created by Jonathan on 2020/4/19.
//

#import "JNSocketConnect.h"
#import "JNEncryption.h"
#import "JNPACManager.h"

@interface JNSocketConnect ()<GCDAsyncSocketDelegate>
@property (nonatomic, strong) GCDAsyncSocket *remoteSocket;
@property (nonatomic, strong) GCDAsyncSocket *derectConnectSocket;
@property (nonatomic, strong) NSString *intactString; //一条完整的加密数据
@property (nonatomic, strong) NSData *requestData;
@property (nonatomic, strong) NSString *httpMethod;
@end

@implementation JNSocketConnect

- (instancetype)init
{
    self = [super init];
    if (self) {
        _intactString = @"";
    }
    return self;
}
/// 开始连接远程服务器
- (void)startRemoteConnect
{
    if (self.remoteSocket) {
        return;
    }
    self.remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.connectQueue];
    NSError *error = nil;
    [self.remoteSocket connectToHost:self.tunnelModel.ipAddress onPort:self.tunnelModel.port.integerValue withTimeout:5 error:&error];
    if (error) {
        //失败则 断开连接
        [self.clientSocket disconnect];
    }
}

// 不需要通过代理的连接
- (void)connectDerectWithHost:(NSString *)host port:(NSString *)port
{
    if (self.derectConnectSocket) {
        return;
    }
    self.derectConnectSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.connectQueue];
    NSError *error = nil;
    [self.derectConnectSocket connectToHost:host onPort:port.integerValue withTimeout:5 error:&error];
    if (error) {
        //失败则 断开连接
        [self.clientSocket disconnect];
    }
}

- (void)writeData:(NSData *)data
{
    if (!self.remoteSocket && !self.derectConnectSocket) {
        self.requestData = data;
        
        if (!self.tunnelModel.pacMode) { //全局代理
            ///需要走代理
            [self startRemoteConnect];
        }
        else{
            //  拿到http请求 判断是否走代理
             NSString *requestString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             if (requestString) {
                 NSString *host = nil;
                 NSString *port = nil;
                 NSString *method = nil;
                 BOOL needed = [[JNPACManager shareInstance] needRemoteServer:requestString host:&host port:&port httpMethod:&method];
                 if (needed ) {
                     ///需要走代理
                     [self startRemoteConnect];
                 }
                 else{
                     self.httpMethod = method;
                     [self connectDerectWithHost:host port:port];
                 }
             }
        }
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.connectQueue, ^{
        if (weakSelf.remoteSocket.isConnected || weakSelf.derectConnectSocket.isConnected) {
            if (weakSelf.derectConnectSocket) {
                [weakSelf.derectConnectSocket writeData:data withTimeout:-1 tag:5];
            }
            else if(weakSelf.remoteSocket){
                //将数据加密
                NSData *eData = [[JNEncryption shareInstance] encryptData:data tunnelModel:weakSelf.tunnelModel];
                [weakSelf.remoteSocket writeData:eData withTimeout:-1 tag:3];
            }
        }

    });

}

#pragma mark - socket delegate -

//已经连接到服务器
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(nonnull NSString *)host port:(uint16_t)port{
    //连接成功或者收到消息，必须开始read，否则将无法收到消息,
    //不read的话，缓存区将会被关闭
//    // -1 表示无限时长 ,永久不失效
    [sock readDataWithTimeout:-1 tag:2];
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.connectQueue, ^{
        if (self.derectConnectSocket) {
            // 如果是CONNECT 反馈连接成功
            if ([weakSelf.httpMethod isEqualToString:@"CONNECT"]) {
                weakSelf.requestData = nil;
                NSString *respone = @"HTTP/1.1 200 Connection established\r\n\r\n";
                [weakSelf.clientSocket writeData:[respone dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:5];
            }
            if (weakSelf.requestData) {
                [weakSelf.derectConnectSocket writeData:weakSelf.requestData withTimeout:-1 tag:3];
                weakSelf.requestData = nil;
            }
        }
        else if(self.remoteSocket){
            if (weakSelf.requestData) {
                NSData *eData = [[JNEncryption shareInstance] encryptData:weakSelf.requestData  tunnelModel:weakSelf.tunnelModel];
                [weakSelf.remoteSocket writeData:eData withTimeout:-1 tag:3];
                weakSelf.requestData = nil;
            }
        }
    });
}

// 连接断开
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    self.intactString = @"";
}

//已经接收服务器返回来的数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    //连接成功或者收到消息，必须开始read，否则将无法收到消息
    //不read的话，缓存区将会被关闭
    // -1 表示无限时长 ， tag
    // 解密数据
    [sock readDataWithTimeout:-1 tag:2];
    
    if (!data.length) {
        //     应答本机请求
        [self.clientSocket writeData:data withTimeout:-1 tag:4];
        return;
    }
    //直连不需要数据解密
    if(self.derectConnectSocket){
        [self.clientSocket writeData:data withTimeout:-1 tag:5];
        return;
    }
    
    NSString *receiveData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    BOOL enterIsLastChar = NO;
    if ([[receiveData substringFromIndex:receiveData.length - 1] isEqualToString:@"#"]) {
        enterIsLastChar = YES;
    }
    if ([receiveData containsString:@"#"]) {
        NSArray *arr = [receiveData componentsSeparatedByString:@"#"];
        //用完了 设置为空
        receiveData = @"";
        
        for (NSInteger i = 0; i < arr.count; i++) {
            NSString *string = arr[i];
            if ([string isEqualToString:@""]) {
                continue;
            }
            if (i == arr.count - 1  && !enterIsLastChar) {// 最后一个不是完整数据 赋值给self.intactString 等待拼接下一条数据
                self.intactString = [NSString stringWithFormat:@"%@%@", self.intactString, string];
            }
            else{
                self.intactString = [NSString stringWithFormat:@"%@%@", self.intactString, string];
                NSData *dData = [[JNEncryption shareInstance] decryptData:[self.intactString dataUsingEncoding:NSUTF8StringEncoding]];
                self.intactString = @"";
                if (data == nil) {
                    [self.clientSocket disconnect];
                }
                else{
                    //     应答本机请求
                    [self.clientSocket writeData:dData withTimeout:-1 tag:4];
                }
            }
        }
    }
    else{ //没有结束符  等待下一条数据
        self.intactString = [self.intactString stringByAppendingString:receiveData];
    }
}

//消息发送成功 代理函数 向服务器 发送消息
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{

}

@end
