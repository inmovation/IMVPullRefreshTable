//
//  TopRefreshViewController.m
//  SFPullRefreshDemo
//
//  Created by shaohua.chen on 10/16/14.
//  Copyright (c) 2014 shaohua.chen. All rights reserved.
//

#import "TopRefreshViewController.h"
#import "IMVPullRefreshTableView.h"

@interface TopRefreshViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *items;
@property (assign, nonatomic) NSInteger page;

@property (strong, nonatomic) IMVPullRefreshTableView *table;

@end

@implementation TopRefreshViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _items = [NSMutableArray array];
    
    _table = [[IMVPullRefreshTableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) style:UITableViewStylePlain pullRefreshType:PRTypeTopRefreshBottomLoad];
//    _table.tintColor = [UIColor redColor];
    _table.dataSource = self;
    _table.delegate = self;
    _table.tableFooterView = [[UIView alloc] init];
    _table.autoLoading = YES;
    [self.view addSubview:_table];

    [_table addTarget:self loadMoreAction:@selector(loadStrings)];
    [_table addTarget:self refreshAction:@selector(loadStrings)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)loadStrings
{
    [self requestDataAtPage:self.table.page success:^(NSArray *strings) {
        if (self.table.isRefreshing) {
            [self.items removeAllObjects];
        }
        [self.items addObjectsFromArray:strings];

        if (strings.count<10) {
            [self.table reachedEnd];
        }
        if (self.items.count<=0) {
            [self.table showHint:@"empty"];
        }
        [self.table reloadData];
        [self.table finishLoading];
    } failure:^(NSString *msg) {
        [self.items removeAllObjects];
        [self.table reloadData];
        [self.table finishLoading];
        [self.table showHint:msg];
    }];
}


#pragma mark - UITableViewDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return _items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellId = @"cellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
//        cell.backgroundColor = [UIColor greenColor];
    }
    cell.textLabel.text = [_items objectAtIndex:indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (void)requestDataAtPage:(NSInteger)page success:(void(^)(NSArray *))success failure:(void(^)(NSString *))failure
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1.5);
        NSMutableArray *arr = [NSMutableArray array];
        if (page<3) {
            for (int i=0; i<10; i++) {
                [arr addObject:[NSString stringWithFormat:@"this is row%li", i+page*10]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(arr);
                }
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(arr);
                }
//                if (failure) {
//                    failure(@"服务器错误！");
//                }
            });
        }
        
    });
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
