//
//  JNProxyModel.h
//  wConnect
//
//  Created by Jonathan on 2020/4/13.
//  Copyright © 2020 JN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YYModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface JNTunnelModel : NSObject

@property (nonatomic, strong) NSString *tagId;

///标签
@property (nonatomic, strong) NSString *tagName;
///ip地址
@property (nonatomic, strong) NSString *ipAddress;
///端口号
@property (nonatomic, strong) NSString *port;

///是否自动代理 默认YES
@property (nonatomic, assign) BOOL pacMode;

/// 是否需要验证 默认YES
@property (nonatomic, assign) BOOL authRequired;
/// 用户名
@property (nonatomic, strong) NSString *userName;
/// 密码
@property (nonatomic, strong) NSString *password;


+ (nullable JNTunnelModel *)getSavedConnectModel;

- (void)saveToDisk;

- (NSDictionary *)json;
@end

NS_ASSUME_NONNULL_END
