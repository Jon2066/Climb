//
//  JNStartProxyController.m
//  wConnect
//
//  Created by Jonathan on 2020/4/13.
//  Copyright © 2020 JN. All rights reserved.
//

#import "JNStartProxyController.h"
#import <NetworkExtension/NetworkExtension.h>
#import "JNTunnelModel.h"
#import "JNSettingController.h"

@interface JNStartProxyController ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *serverNameLabel;

@property (nonatomic, strong) JNTunnelModel *currentTunnelModel;

@property (nonatomic, assign) BOOL observerAdded;
@end

@implementation JNStartProxyController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self checkState];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadNavItems];
    
    self.startButton.layer.cornerRadius = 60;
    self.startButton.layer.masksToBounds = YES;
    // Do any additional setup after loading the view.
    
//    ///保存在userDefaults
//    [model saveToDisk];
    
}

- (void)checkState
{
    [self getCurrentTunnelManager:^(NETunnelProviderManager * _Nullable manager) {
        if (manager) {
            [self handleVpnStateDidChange:manager.connection.status];
        }
    }];
    JNTunnelModel *model = [JNTunnelModel getSavedConnectModel];
    if (model) {
        self.currentTunnelModel = model;
        self.serverNameLabel.text = model.tagName;
    }
}

- (void)loadNavItems
{
    UIBarButtonItem *setting = [[UIBarButtonItem alloc] initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(settingAction:)];
    self.navigationItem.rightBarButtonItem = setting;
}

- (IBAction)startAction:(UIButton *)sender {
    if (sender.selected) {
        sender.selected = NO;
        //停止
        [self getCurrentTunnelManager:^(NETunnelProviderManager * _Nullable manager) {
            if (manager) {
                [manager.connection stopVPNTunnel];
            }
        }];
    }
    else{
        [self createManagerIfNeededWithModel:self.currentTunnelModel completion:^(NETunnelProviderManager * _Nullable manager, NSString * _Nullable message) {
            if (manager) {
                [self addVPNNotificationWithManager:manager];
                NSError *startError = nil;
                [manager.connection startVPNTunnelWithOptions:@{} andReturnError:&startError];
                if (startError) {
                    NSLog(@"vpn 启动失败 %@", startError.localizedDescription);
                    //TODO::失败处理
                }
                else{
                    NSLog(@"vpn 启动成功");
                    sender.selected = YES;
                }
            }
            else{
                //TODO::错误处理
                sender.selected = NO;
            }
        }];
    }
}

- (void)settingAction:(id)sender {
    JNSettingController *settingVC = [[JNSettingController alloc] init];
    [self.navigationController pushViewController:settingVC animated:YES];
}


- (void)removeDUPFile:(NSArray *)managers
{
    for (NETunnelProviderManager *manager in managers) {
        [manager removeFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            NSLog(@"移除VPN配置文件 %@", error?error.localizedDescription:@"成功");
        }];
    }
}

- (void)addVPNNotificationWithManager:(NETunnelProviderManager *)manager
{
    if (self.observerAdded) {
        return;
    }
    self.observerAdded = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(vpnDidChange:) name:NEVPNStatusDidChangeNotification object:manager.connection];
}

- (void)vpnDidChange:(NSNotification *)noti
{
    NEVPNConnection *connection = noti.object;
    [self handleVpnStateDidChange:connection.status];
}

- (void)handleVpnStateDidChange:(NEVPNStatus)status
{
    switch (status) {
        case NEVPNStatusInvalid:
        {
            NSLog(@"VPN状态 无效");
            self.startButton.selected = NO;
            break;
        }
        case NEVPNStatusConnected:
        {
            NSLog(@"VPN状态 已连接");
            self.startButton.selected = YES;
            break;
        }
        case NEVPNStatusConnecting:
        {
            NSLog(@"VPN状态 正在连接");
            self.startButton.selected = YES;
            break;
        }
        case NEVPNStatusDisconnected:{
            NSLog(@"VPN状态 连接已断开");
            self.startButton.selected = NO;
            break;
        }
        case NEVPNStatusDisconnecting:{
            NSLog(@"VPN状态 正在断开连接");
            self.startButton.selected = NO;
            break;
        }
        default:
            break;
    }
}

#pragma mark - load manager -

- (void)getCurrentTunnelManager:(void(^)(NETunnelProviderManager *_Nullable manager))completion
{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        if (completion) {
            completion(managers.count?managers[0]:nil);
        }
    }];
}

- (void)createManagerIfNeededWithModel:(JNTunnelModel *)model
                            completion:(void(^)(NETunnelProviderManager *_Nullable manager, NSString * _Nullable message))completion
{
    [NETunnelProviderManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETunnelProviderManager *> * _Nullable managers, NSError * _Nullable error) {
        NETunnelProviderManager *manager = nil;
        if (managers.count) {
            NSLog(@"已存在manager");
            for (NETunnelProviderManager *aManager in managers) {
                NSLog(@"amanager %@", aManager.localizedDescription);
            }
            manager = managers[0];
            if (managers.count > 1) {
                [self removeDUPFile:managers];
            }
        }
        else{
            manager = [[NETunnelProviderManager alloc] init];
            manager.localizedDescription = @"Climb";
            NETunnelProviderProtocol *protocol = [[NETunnelProviderProtocol alloc] init];
            protocol.serverAddress = @"127.0.0.1";
            manager.protocolConfiguration = protocol;
        }
        ((NETunnelProviderProtocol *)manager.protocolConfiguration).providerConfiguration = [model json];
        [manager setEnabled:YES];
        [manager saveToPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"saveToPreferences error %@", error.localizedDescription);
                if (completion) {
                    completion(nil, error.localizedDescription);
                }
            }
            else{
                NSLog(@"saveToPreferences 成功");
                [manager loadFromPreferencesWithCompletionHandler:^(NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"读取manager 失败 %@", error.localizedDescription);
                        if (completion) {
                            completion(nil, error.localizedDescription);
                        }
                    }
                    else{
                        NSLog(@"读取manager 成功");
                        if (completion) {
                            completion(manager, nil);
                        }
                    }
                }];
            }
        }];
    }];
}
@end
