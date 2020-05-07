//
//  JNIPTool.h
//  JNClimbServer
//
//  Created by Jonathan on 2020/4/18.
//

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import "JNTunnelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface JNNetworkSetting : NSObject
/// 设置代理规则
+ (NEPacketTunnelNetworkSettings *)networkSettings;

/// 本地proxy代理端口
+ (NSInteger)localProxyServerPort;
@end

NS_ASSUME_NONNULL_END
