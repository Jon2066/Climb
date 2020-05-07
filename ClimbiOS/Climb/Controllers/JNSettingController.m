//
//  JNSettingController.m
//  wConnect
//
//  Created by Jonathan on 2020/4/13.
//  Copyright © 2020 JN. All rights reserved.
//

#import "JNSettingController.h"
#import "JNTunnelModel.h"

@interface JNSettingController ()
@property (weak, nonatomic) IBOutlet UITextField *serverNameTF;
@property (weak, nonatomic) IBOutlet UITextField *IPTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *usernameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UISwitch *pacSwitch;
@property (nonatomic, strong) JNTunnelModel *currentModel;
@end

@implementation JNSettingController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.title = @"设置";
    
    self.currentModel = [JNTunnelModel getSavedConnectModel];
    if (self.currentModel) {
        self.serverNameTF.text = self.currentModel.tagName;
        self.IPTF.text = self.currentModel.ipAddress;
        self.portTF.text = self.currentModel.port;
        self.usernameTF.text = self.currentModel.userName;
        self.passwordTF.text = self.currentModel.password;
        self.pacSwitch.on = self.currentModel.pacMode;
    }
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStylePlain target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viweTap)];
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
}

- (void)saveAction
{
    if (self.serverNameTF.text.length
        &&self.IPTF.text.length
        &&self.portTF.text.length
        &&self.usernameTF.text.length
        &&self.passwordTF.text.length) {
        if (!self.currentModel) {
            self.currentModel = [[JNTunnelModel alloc] init];
        }
        self.currentModel.tagName = self.serverNameTF.text;
        self.currentModel.ipAddress = self.IPTF.text;
        self.currentModel.port = self.portTF.text;
        self.currentModel.userName = self.usernameTF.text;
        self.currentModel.password = self.passwordTF.text;
        self.currentModel.pacMode = self.pacSwitch.on;
        [self.currentModel saveToDisk];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)viweTap
{
    for (UIView *subView in self.view.subviews) {
        for (UIView *ssView in subView.subviews) {
            [ssView resignFirstResponder];
        }
    }
}
@end
