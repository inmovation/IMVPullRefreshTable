//
//  SFPullRefreshTableView.m
//  SFPullRefreshDemo
//
//  Created by shaohua.chen on 10/16/14.
//  Copyright (c) 2014 shaohua.chen. All rights reserved.
//

#import "IMVPullRefreshTableView.h"
#import <QuartzCore/QuartzCore.h>

#define PRLoadingViewHeight 60.0

#define KeyPathContentSize @"contentSize"
#define KeyPathContentOffset @"contentOffset"

#define PRAnimationDuration 0.2

typedef enum {
    PRStateNormal = 0,
    PRStateLoading,
    PRStateReachEnd
} PRState;


#pragma mark SFPullRefreshTableView
@interface IMVPullRefreshTableView ()<UIScrollViewDelegate>

@property (assign, nonatomic) PullRefreshType prType;

@property (assign, nonatomic) CGFloat orignContentOffsetY; //若navigationBar半透明，则table会有一个初始的contentOffset，和contentInset
@property (assign, nonatomic) CGFloat orignContentInsetTop;

@property (weak, nonatomic) id refreshTarget;
@property (assign, nonatomic) SEL refreshAction;

@property (weak, nonatomic) id loadTarget;
@property (assign, nonatomic) SEL loadAction;

@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (assign, nonatomic) PRState loadingState;
@property (strong, nonatomic) UIView *loadingView;
@property (strong, nonatomic) UIActivityIndicatorView *loadingActivity;
@property (strong, nonatomic) UILabel *loadingLabel;
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
        _orignContentOffsetY = -CGFLOAT_MAX;
        _orignContentInsetTop = -CGFLOAT_MAX;
        self.prType = prType;
        
        [self addObserver:self forKeyPath:KeyPathContentSize options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:KeyPathContentOffset options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:KeyPathContentSize];
    [self removeObserver:self forKeyPath:KeyPathContentOffset];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (self.isRefreshing) {//tabbar每切换一次都会调用willMoveToWindow,导致orignContentInsetTop不正确
        return;
    }
    if (newWindow != nil) {
        _orignContentInsetTop = self.contentInset.top;
        if (self.contentOffset.y == -64 | self.contentOffset.y == 0) {
            _orignContentOffsetY = self.contentOffset.y;
        }
    }
}

- (NSString *)reachedEndText
{
    if (!_reachedEndText) {
        _reachedEndText = @"没有了";
    }
    return _reachedEndText;
}

- (void)setReachedEndText:(NSString *)reachEndText
{
    self.loadingLabel.text = reachEndText;
}

- (UIColor *)tintColor
{
    if (!_tintColor) {
        _tintColor = [UIColor grayColor];
    }
    return _tintColor;
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    _loadingLabel.textColor = tintColor;
    _refreshControl.tintColor = tintColor;
    _loadingActivity.color = tintColor;
}

- (UIView *)loadingView
{
    if (!_loadingView) {
        _loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, PRLoadingViewHeight)];
        _loadingView.backgroundColor = [UIColor clearColor];
        
        _loadingLabel = [[UILabel alloc] initWithFrame:_loadingView.bounds];
        _loadingLabel.backgroundColor = [UIColor clearColor];
        _loadingLabel.font = [UIFont systemFontOfSize:15.0];
        _loadingLabel.textColor = self.tintColor;
        _loadingLabel.textAlignment = NSTextAlignmentCenter;
        _loadingLabel.text = self.reachedEndText;
        _loadingLabel.hidden = YES;
        [_loadingView addSubview:_loadingLabel];
        
        _loadingActivity = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 15, 15)];
        _loadingActivity.center = CGPointMake(_loadingView.frame.size.width/2, _loadingView.frame.size.height/2);
        _loadingActivity.color = self.tintColor;
        [_loadingView addSubview:_loadingActivity];
    }
    return _loadingView;
}

- (UIRefreshControl *)refreshControl
{
    if (!_refreshControl) {
        _refreshControl = [[UIRefreshControl alloc] init];
        [_refreshControl addTarget:self action:@selector(refreshControlChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _refreshControl;
}

//开始刷新
- (void)refreshControlChanged:(UIRefreshControl *)refreshControl
{
    _isRefreshing = YES;
    self.loadingState = PRStateNormal;
    if (_refreshTarget && [_refreshTarget respondsToSelector:_refreshAction])
    {
        ((void (*)(id, SEL))[_refreshTarget methodForSelector:_refreshAction])(_refreshTarget, _refreshAction);
    }
}

- (void)setPrType:(PullRefreshType)prType
{
    _prType = prType;
    switch (prType) {
        case PRTypeTopRefresh:
        {
            [self addSubview:self.refreshControl];
            break;
        }
        case PRTypeBottomLoad:
        {
            [self addSubview:self.loadingView];
            break;
        }
        case PRTypeTopRefreshBottomLoad:
        {
            [self addSubview:self.refreshControl];
            [self addSubview:self.loadingView];
            break;
        }
        case PRTypeTopLoad:
        {
            _scrollToBottom = YES;
            [self addSubview:self.loadingView];
            [self.loadingView setFrame:CGRectMake(0, -PRLoadingViewHeight, self.frame.size.width, PRLoadingViewHeight)];
            break;
        }
        default:
            break;
    }
}

- (void)setLoadingState:(PRState)loadingState
{
    _loadingState = loadingState;
    switch (_loadingState) {
        case PRStateNormal:
        {
            [_loadingActivity stopAnimating];
            _loadingActivity.hidden = YES;
            _loadingLabel.hidden = YES;
            break;
        }
        case PRStateLoading:
        {
            [_loadingActivity startAnimating];
            _loadingActivity.hidden = NO;
            _loadingLabel.hidden = YES;
            break;
        }
        case PRStateReachEnd:
        {
            self.contentInset = UIEdgeInsetsMake(_orignContentInsetTop, 0, 0, 0);
            if (_prType == PRTypeTopLoad) { // 这里设置防抖动没效果，因为还会调用contentSize的kvo

            }
            else
            {
                self.contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y+PRLoadingViewHeight);
            }
            
            [_loadingActivity stopAnimating];
            _loadingActivity.hidden = YES;
            _loadingLabel.hidden = NO;
            break;
        }
            
        default:
            break;
    }
}

- (void)reachedEnd {
    self.loadingState = PRStateReachEnd;
}

- (void)setRefreshTarget:(id)target action:(SEL)action
{
    _refreshTarget = target;
    _refreshAction = action;
}

- (void)setLoadTarget:(id)target action:(SEL)action
{
    _loadTarget = target;
    _loadAction = action;
}

- (void)pullToRefresh {
    if (self.prType == PRTypeTopRefresh | self.prType == PRTypeTopRefreshBottomLoad) {
        [self.refreshControl beginRefreshing];
    }
}

#pragma mark - Scroll methods
- (void)tableViewDidScroll{
    
    if (_loadingState != PRStateNormal || _prType == PRTypeNormal || _prType == PRTypeTopRefresh) {
        return;
    }
    
    CGPoint offset = self.contentOffset;
    offset.y -= _orignContentOffsetY;

    CGSize size = self.frame.size;
    CGSize contentSize = self.contentSize;
    if (contentSize.height < self.frame.size.height) {
        contentSize.height = self.frame.size.height;
    }

    if (_prType == PRTypeTopLoad) {
        if (offset.y < 0) {
            self.loadingState = PRStateLoading;
            if (_loadTarget && [_loadTarget respondsToSelector:_loadAction])
            {
                ((void (*)(id, SEL))[_loadTarget methodForSelector:_loadAction])(_loadTarget, _loadAction);
            }
            [UIView animateWithDuration:PRAnimationDuration/2 animations:^{
                self.contentInset = UIEdgeInsetsMake(PRLoadingViewHeight+_orignContentInsetTop, 0, 0, 0);
            }];
        }
    }
    else if (_prType == PRTypeBottomLoad || _prType == PRTypeTopRefreshBottomLoad)
    {
        float yMargin = self.contentOffset.y + size.height - contentSize.height;
        if ( yMargin > 0) {  //footer will appeared
            
            self.loadingState = PRStateLoading;
            if (_loadTarget && [_loadTarget respondsToSelector:_loadAction])
            {
                ((void (*)(id, SEL))[_loadTarget methodForSelector:_loadAction])(_loadTarget, _loadAction);
            }
            
            [UIView animateWithDuration:PRAnimationDuration/2 animations:^{
                self.contentInset = UIEdgeInsetsMake(_orignContentInsetTop, 0, PRLoadingViewHeight, 0);
            }];
        }
    }
}

- (void)finishLoading
{
    [self finishLoadingWithOffset:0];
}

- (void)finishLoadingWithOffset:(CGFloat)offset
{
    _isRefreshing = NO;
    if (_prType == PRTypeTopRefresh || _prType == PRTypeTopRefreshBottomLoad) {
        [self.refreshControl endRefreshing];
    }
    if (_loadingState == PRStateLoading) //只有loading状态才重新设置为normal
    {
        self.loadingState = PRStateNormal;
    }
    
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self) {
        if ([keyPath isEqualToString:KeyPathContentSize]) {
            CGFloat preContentHeight = [[change objectForKey:@"old"] CGSizeValue].height;
            CGFloat curContentHeight = [[change objectForKey:@"new"] CGSizeValue].height;
            if (preContentHeight == curContentHeight) {
                return;
            }
            CGRect frame = _loadingView.frame;
            if (_prType == PRTypeTopRefreshBottomLoad || _prType == PRTypeBottomLoad) {
                CGSize contentSize = self.contentSize;
                frame.origin.y = contentSize.height < self.frame.size.height ? self.frame.size.height : contentSize.height;
            }
            _loadingView.frame = frame;
            
            if (_prType == PRTypeTopLoad) { //为了加载后不抖动
                
                if (curContentHeight-preContentHeight>0) {
                    CGPoint offset = self.contentOffset;
                    if (preContentHeight == 0 && _scrollToBottom) {
                        offset.y = curContentHeight>self.frame.size.height?(curContentHeight-self.frame.size.height):0;
                    }
                    if (preContentHeight > 0)
                    {
                        offset.y += curContentHeight-preContentHeight;
                    }
                    if (_loadingState == PRStateReachEnd) { //防止到底时抖动
                        offset.y -= PRLoadingViewHeight;
                    }
                    self.contentOffset = offset;
                }
            }
        }
        else if ([keyPath isEqualToString:KeyPathContentOffset])
        {
            if (_orignContentOffsetY <-1000) { // table初始化的时候contentOffset也会有变化，_orignContentOffsetY初始化为很小的负数
                return;
            }
            [self tableViewDidScroll];
        }
    }
}

@end