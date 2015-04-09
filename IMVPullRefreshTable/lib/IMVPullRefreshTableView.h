//
//  SFPullRefreshTableView.h
//  SFPullRefreshDemo
//
//  Created by shaohua.chen on 10/16/14.
//  Copyright (c) 2014 shaohua.chen. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    PRTypeNormal = 0, //默认的UITableView
    PRTypeTopRefresh, //只顶部刷新
    PRTypeBottomLoad, //只底部加载更多
    PRTypeTopRefreshBottomLoad, //顶部刷新，底部加载更多
    PRTypeTopLoad, //只顶部加载更多
} PullRefreshType;

typedef void (^RefreshHandler)();
typedef void (^LoadHandler)();

@interface IMVPullRefreshTableView : UITableView

/**
 *  判断table是不是在刷新。
 *  当从服务器获取到数据时，可以根据这个变量来决定是否需要删除之前的数据。
 */
@property (assign, nonatomic) BOOL isRefreshing;

/**
 *  当table第一次加载时，并且 PullRefreshType == PRTypeTopLoad, 可以设置这个变量来让table是否滚到最底端。
 *  默认值是YES。
 */
@property (assign, nonatomic) BOOL scrollToBottom;

/**
 *  数据加载完的文字
 *  默认:@"没有了"
 */
@property (copy, nonatomic) NSString *reachedEndText;

@property (strong, nonatomic) UIColor *tintColor;

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style pullRefreshType:(PullRefreshType)prType;

/**
 *  用该方法来处理刷新
 *
 *  @param target 处理刷新的对象
 *  @param action 处理的方法
 */
- (void)setRefreshTarget:(id)target action:(SEL)action;
/**
 *  用该方法来处理加载更多
 *
 *  @param target 处理加载更多的对象
 *  @param action 处理的方法
 */
- (void)setLoadTarget:(id)target action:(SEL)action;

/**
 *  @Author liang.tao, 15-02-03 16:02:15
 *
 *  @brief  tableView自动执行下拉动画刷新
 */

/**
 *  结束加载或刷新
 */
- (void)finishLoading;

/**
 *  需要在数据加载完时调用。
 */
- (void)reachedEnd;

- (void)pullToRefresh;

@end