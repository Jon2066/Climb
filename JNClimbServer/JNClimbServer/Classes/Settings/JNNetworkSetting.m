//
//  JNIPTool.m
//  JNClimbServer
//
//  Created by Jonathan on 2020/4/18.
//

#import "JNNetworkSetting.h"
#import "JNPACManager.h"

@implementation JNNetworkSetting
+ (NEPacketTunnelNetworkSettings *)networkSettings
{
    NEPacketTunnelNetworkSettings *netSettings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"8.8.8.8"];
    netSettings.MTU = @(1500);
    
    NSInteger  port = [self localProxyServerPort];
    // 随便填ip 开启本地代理
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"10.10.10.10"] subnetMasks:@[@"255.255.255.0"]];
    ipv4Settings.includedRoutes = @[[NEIPv4Route defaultRoute]];
    netSettings.IPv4Settings = ipv4Settings;
    
    NSString *ip = @"127.0.0.1";
    
    NEProxySettings *proxySettings = [[NEProxySettings alloc] init];
    proxySettings.excludeSimpleHostnames = YES;

    proxySettings.HTTPEnabled = YES;
    proxySettings.HTTPServer = [[NEProxyServer alloc] initWithAddress:ip port:port];
    
    proxySettings.HTTPSEnabled = YES;
    proxySettings.HTTPSServer = [[NEProxyServer alloc] initWithAddress:ip port:port];

    
    proxySettings.exceptionList = [self appleExceptionList];
    netSettings.proxySettings = proxySettings;
    return netSettings;
}

+ (NSInteger)localProxyServerPort
{
    return 6606;
}

+ (NSArray *)appleExceptionList
{
    return @[
        @"api.smoot.apple.com",
        @"configuration.apple.com",
        @"xp.apple.com",
        @"smp-device-content.apple.com",
        @"guzzoni.apple.com",
        @"captive.apple.com",
        @"*.ess.apple.com",
        @"*.push.apple.com",
        @"*.push-apple.com.akadns.net",
        @"ocsp.apple.com",
        @"*.smoot.apple.cn",
        @"*.icloud.com.cn",
        @"valid.apple.com",
        @"health.apple.com",
        @"weather-data.apple.com"
    ];
}
@end
