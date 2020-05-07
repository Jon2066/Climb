//
//  JNProxyModel.m
//  wConnect
//
//  Created by Jonathan on 2020/4/13.
//  Copyright © 2020 JN. All rights reserved.
//

#import "JNTunnelModel.h"

#define JN_ProxyModel_SaveKEY @"jn.wang.wconnect_proxy_savekey"

@implementation JNTunnelModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        _authRequired = YES;
        _pacMode = YES;
    }
    return self;
}

- (void)saveToDisk
{
    NSString *json = [self yy_modelToJSONString];
    [[NSUserDefaults standardUserDefaults] setObject:json forKey:JN_ProxyModel_SaveKEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (JNTunnelModel *)getSavedConnectModel
{
    NSString *json = [[NSUserDefaults standardUserDefaults] objectForKey:JN_ProxyModel_SaveKEY];
    if (json) {
        return [self yy_modelWithJSON:json];
    }
    return nil;
}

- (NSDictionary *)json
{
    return [self yy_modelToJSONObject];
}
@end
