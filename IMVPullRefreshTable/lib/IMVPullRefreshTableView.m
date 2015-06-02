//
//  SFPullRefreshTableView.m
//  SFPullRefreshDemo
//
//  Created by shaohua.chen on 10/16/14.
//  Copyright (c) 2014 shaohua.chen. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "IMVPullRefreshTableView.h"
#import "IMVLoadMoreControl.h"
#import "IMVRefreshControl.h"


@interface IMVPullRefreshTableView ()<UIScrollViewDelegate>

@property (assign, nonatomic) CGFloat orignOffsetY; //若navigationBar半透明，则table会有一个初始的contentOffset，和contentInset
@property (assign, nonatomic) CGFloat orignInsetTop;

@property (weak, nonatomic) id refreshTarget;
@property (assign, nonatomic) SEL refreshAction;

@property (weak, nonatomic) id loadTarget;
@property (assign, nonatomic) SEL loadAction;

@property (strong, nonatomic) IMVRefreshControl *refreshControl;

@property (strong, nonatomic) IMVLoadMoreControl *loadMoreControl;

@property (strong, nonatomic) UILabel *hintLabel;
@property (strong, nonatomic) UIView *hintView;

@end

@implementation IMVPullRefreshTableView
@synthesize reachedEndText = _reachedEndText;
@synthesize tintColor = _tintColor;

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [self initWithFrame:frame style:style pullRefreshType:PRTypeNormal];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style pullRefreshType:(PullRefreshType)prType
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        
        _scrollToBottom = NO;
        _isRefreshing = NO;
        _orignOffsetY = CGFLOAT_MAX;
        _orignInsetTop = CGFLOAT_MAX;
        _page = 0;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.backgroundView= backgroundView;
        
        self.tableFooterView = [[UIView alloc] init];
        
        [self addSubview:self.hintView];
        self.prType = prType;
    }
    return self;
}

- (void)dealloc
{
    if (_refreshControl) {
        [_refreshControl removeTarget:self];
    }
    if (_loadMoreControl) {
        [_loadMoreControl removeTarget:self];
    }
}


#pragma mark - setter getter
- (BOOL)isRefreshing
{
    if (_refreshControl) {
        return _refreshControl.isRefreshing;
    }
    else {
        return NO;
    }
}

- (void)setReachedEndText:(NSString *)reachEndText
{
    self.loadMoreControl.reachedEndText = reachEndText;
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    if (_loadMoreControl) {
        self.loadMoreControl.tintColor = tintColor;
    }
    if (_refreshControl) {
        self.refreshControl.tintColor = tintColor;
    }
}

- (IMVLoadMoreControl *)loadMoreControl
{
    if (!_loadMoreControl) {
        _loadMoreControl = [[IMVLoadMoreControl alloc] init];
        [_loadMoreControl addTarget:self loadMoreAction:@selector(loadMore)];
    }
    return _loadMoreControl;
}

- (IMVRefreshControl *)refreshControl
{
    if (!_refreshControl) {
        _refreshControl = [[IMVRefreshControl alloc] init];
        [_refreshControl addTarget:self refreshAction:@selector(refresh)];
    }
    return _refreshControl;
}

- (UIView *)hintView
{
    if (!_hintView) {
        _hintView = [[UIView alloc] initWithFrame:self.bounds];
        _hintView.backgroundColor = [UIColor clearColor];
        
        _hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, _hintView.frame.size.width-20, _hintView.frame.size.height*0.618)];
        _hintLabel.backgroundColor = [UIColor clearColor];
        _hintLabel.font = [UIFont systemFontOfSize:17.0];
        _hintLabel.textColor = self.tintColor;
        _hintLabel.numberOfLines = 0;
        _hintLabel.textAlignment = NSTextAlignmentCenter;
        [_hintView addSubview:_hintLabel];
    }
    return _hintView;
}




#pragma mark private method
//开始加载更多
- (void)loadMore
{
    self.hintView.hidden = YES;
    if (_loadAction && [_loadTarget respondsToSelector:_loadAction])
    {
        ((void (*)(id, SEL))[_loadTarget methodForSelector:_loadAction])(_loadTarget, _loadAction);
        _page ++; //加载更多后page+1
    }
}

//开始刷新
- (void)refresh
{
    self.hintView.hidden = YES;

    if (_refreshTarget && [_refreshTarget respondsToSelector:_refreshAction])
    {
        _page = 0; //刷新前page=0
        ((void (*)(id, SEL))[_refreshTarget methodForSelector:_refreshAction])(_refreshTarget, _refreshAction);
    }
}

- (void)setPrType:(PullRefreshType)prType
{
    _prType = prType;
    switch (prType) {
        case PRTypeTopRefresh: {
            [self.backgroundView addSubview:self.refreshControl];
            break;
        }
        case PRTypeBottomLoad: {
            [self addSubview:self.loadMoreControl];
            break;
        }
        case PRTypeTopRefreshBottomLoad: {
            [self.backgroundView addSubview:self.refreshControl];
            [self addSubview:self.loadMoreControl];
            break;
        }
        case PRTypeTopLoad: {
            _scrollToBottom = YES;
            
            self.loadMoreControl.isTop = YES;
            [self addSubview:self.loadMoreControl];
            break;
        }
        default:
            break;
    }
}



#pragma mark public method
- (void)reachedEnd {
    if (_loadMoreControl) {
        [_loadMoreControl reachedEnd];
    }
}

- (void)addTarget:(id)target refreshAction:(SEL)action
{
    _refreshTarget = target;
    _refreshAction = action;
}

- (void)addTarget:(id)target loadMoreAction:(SEL)action
{
    _loadTarget = target;
    _loadAction = action;
}

- (void)showHint:(NSString *)hint
{
    _hintLabel.text = hint;
    self.hintView.hidden = NO;
}


- (void)finishLoading
{
    if (_loadMoreControl) {
        [_loadMoreControl finishLoading];
    }
    if (_refreshControl) {
        [_refreshControl finishRefreshing];
    }
}

@end