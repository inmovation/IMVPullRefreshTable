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

@interface IMVPullRefreshTableView : UITableView

@property (assign, nonatomic) PullRefreshType prType;

/**
 *  判断table是不是在刷新。
 *  当从服务器获取到数据时，可以根据这个变量来决定是否需要删除之前的数据。
 */
@property (assign, nonatomic) BOOL isRefreshing;

/**
 *  初始化自动刷新，或者当prType=PRTypeTopLoad时，自动加载更多
 *  默认是YES
 */
@property (assign, nonatomic) BOOL autoLoading;

/**
 *  当前加载第几页，推荐使用这个变量来控制分页
 *  初始0，加载更多会自动加1，刷新会自动清0
 */
@property (assign, nonatomic) NSInteger page;

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
- (void)addTarget:(id)target refreshAction:(SEL)action;
/**
 *  用该方法来处理加载更多
 *
 *  @param target 处理加载更多的对象
 *  @param action 处理的方法
 */
- (void)addTarget:(id)target loadMoreAction:(SEL)action;

/**
 *  结束加载或刷新
 */
- (void)finishLoading;

/**
 *  结束加载或刷新
 */
- (void)refresh;

/**
 *  结束加载或刷新
 */
- (void)loadMore;

/**
 *  当table数据为空时，使用该方法来显示提示文字，比如“服务器错误”，“当前没有数据”，当刷新时会自动消失
 *  @param hint 需要显示的文字
 */
- (void)showHint:(NSString *)hint;

/**
 *  需要在数据加载完时调用。
 */
- (void)reachedEnd;

@end