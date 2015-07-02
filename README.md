
IMVPullRefreshTable is a subclass of UITableView, implements pulling down to refresh, pulling up to load more, pulling down to load more. Support iOS5+.


### Installation with CocoaPods
####You should add repo IMVSpec first(a private repo) :
pod repo add IMVSpec https://github.com/inmovation/IMVSpec.git

```ruby
source 'https://github.com/inmovation/IMVSpec.git'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '5.0'

pod 'IMVPullRefreshTable', '~> 1.1.5'
#other framework
```


### Usage
IMVPullRefreshTable provide a elegant usage, firstly you don't need care about scroll delegate, just init it and do something when request callback, IMVPullRefreshTable will do the rest thing. And IMVPullRefreshTable provide page property, that you can use it to request current page data, you don't need care about page value, IMVPullRefreshTable will do page++ when load data, and page=0 when refresh. Lastly IMVPullRefreshTable provide a hintView, that you can show hints to user, like error message or empty data message. Enjoy it.
#### init
```objective-c
  _table = [[IMVPullRefreshTableView alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStylePlain pullRefreshType:PRTypeTopRefreshBottomLoad];
  _table.dataSource = self;
  _table.delegate = self;
  //_table.tintColor = [UIColor redColor];
  //_table.autoLoading = NO;
  [_table addTarget:self loadMoreAction:@selector(loadStrings)];
  [_table addTarget:self refreshAction:@selector(loadStrings)];
  [self.view addSubview:_table];

```
#### loadData
```objective-c
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
```
