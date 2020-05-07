//
//  JNRACManager.h
//  Climb
//
//  Created by Jonathan on 2020/4/18.
//  Copyright © 2020 JN. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JNPACManager : NSObject

+ (instancetype)shareInstance;

- (BOOL)needRemoteServer:(NSString *)string host:(NSString **)host port:(NSString **)port httpMethod:(NSString **)method;

// 从本地文件读取js
//+ (NSString *)loadPACFromFile;


/*
 
/// 设置到userDefaults 用于客户端编辑
+ (void)saveToUserDefaults:(NSString *)js;

///  客户端读取
+ (NSString *)getFromUserDefaults;

/// PacketTunnel 拓展读取
+ (NSString *)packetTunnelGetFromUserDefaults;

 */

@end

NS_ASSUME_NONNULL_END
