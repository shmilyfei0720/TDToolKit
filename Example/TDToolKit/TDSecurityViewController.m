//
//  TDSecurityViewController.m
//  TDToolKit_Example
//
//  Created by tiandy on 2019/3/14.
//  Copyright © 2019 707357307@qq.com. All rights reserved.
//

#import "TDSecurityViewController.h"
#import <TDToolKit/TDSecurity.h>

@interface TDSecurityViewController ()

@end

@implementation TDSecurityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"TDSecurity";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(50, 100, 100, 40)];
    [btn setTitle:@"md5Test" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(testMD5) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
}

#pragma mark ============actions
-(void)testMD5 {
    
}

@end
