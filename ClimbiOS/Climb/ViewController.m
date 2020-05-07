//
//  ViewController.m
//  Climb
//
//  Created by Jonathan on 2020/4/15.
//  Copyright © 2020 JN. All rights reserved.
//

#import "ViewController.h"
#import "JNStartProxyController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    JNStartProxyController *startController = [[JNStartProxyController alloc] init];
    startController.title = @"Climb";
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:startController];
    
    [self addChildViewController:nav];
    [self.view addSubview:nav.view];
}


@end
