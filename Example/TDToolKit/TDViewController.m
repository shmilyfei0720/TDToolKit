//
//  TDViewController.m
//  TDToolKit
//
//  Created by 707357307@qq.com on 03/14/2019.
//  Copyright (c) 2019 707357307@qq.com. All rights reserved.
//

#import "TDViewController.h"
#import "TDSecurityViewController.h"

@interface TDViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSArray *items;

@end

@implementation TDViewController

#pragma mark ============life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"home";
    self.view.backgroundColor = [UIColor whiteColor];
    self.items = @[@"加密工具(TDSecurity)",@"渲染工具(TDRender)"];
    UITableView *tableView= [[UITableView alloc] initWithFrame:self.view.frame];
    tableView.delegate = self;
    tableView.dataSource = self;
    [tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CELL"];
    tableView.tableFooterView = [UIView new];
    self.tableView = tableView;
    [self.view addSubview:self.tableView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark ============ tablview datasource & delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL" forIndexPath:indexPath];
    cell.textLabel.text = self.items[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        TDSecurityViewController *vc = [[TDSecurityViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
}
@end
