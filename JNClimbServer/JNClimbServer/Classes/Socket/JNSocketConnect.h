//
//  JNRemoteSocket.h
//  AFNetworking
//
//  Created by Jonathan on 2020/4/19.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import "JNTunnelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface JNSocketConnect : NSObject

/// 获得连接和加密信息  连接前设置
@property (nonatomic, strong) JNTunnelModel *tunnelModel;

/// 对应的本机请求的socket 连接前设置
@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, weak) dispatch_queue_t connectQueue;

/// 转发到远端
@property (nonatomic, strong, readonly) GCDAsyncSocket *remoteSocket;

/// 自动代理 不需要连接代理的 直接连接
@property (nonatomic, strong, readonly) GCDAsyncSocket *derectConnectSocket;

/// 转发数据
- (void)writeData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
