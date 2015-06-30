//
//  IMVLoadingControl.m
//  IMVPullRefreshTable
//
//  Created by 陈少华 on 15/5/29.
//  Copyright (c) 2015年 inmovation. All rights reserved.
//

#import "IMVLoadMoreControl.h"

typedef enum {
    LoadMoreStateNormal = 0,
    LoadMoreStateLoading,
    LoadMoreStateReachEnd
} LoadMoreState;

@interface IMVLoadMoreControl ()

@property (weak, nonatomic) UITableView *target;
@property (assign, nonatomic) SEL loadMoreAction;
@property (assign, nonatomic) BOOL isReachedEnd;

@property (assign, nonatomic) CGFloat orignInsetTop;
@property (assign, nonatomic) CGFloat orignOffsetY;
@property (assign, nonatomic) LoadMoreState state;

@property (strong, nonatomic) NSMutableArray *loadingLayers;
@property (strong, nonatomic) CALayer *loadingContainer;
@property (strong, nonatomic) UILabel *reachedEndLabel;

//如果需要自定义，新建子类并重写这几个方法
- (void)setup;
- (void)beginLoading;
- (void)endLoading;

@end

@implementation IMVLoadMoreControl

- (id)init
{
    return [self initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, 60)];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _orignInsetTop = CGFLOAT_MAX;
        _orignOffsetY = CGFLOAT_MAX;
        _tintColor = [UIColor colorWithWhite:110.0/255 alpha:1.0];
        _autoLoadMore = YES;
        [self setup];
    }
    return self;
}


#pragma mark -getter setter
- (void)setReachedEndText:(NSString *)reachedEndText
{
    _reachedEndLabel.text = reachedEndText;
}

- (void)setIsTop:(BOOL)isTop
{
    _isTop = isTop;
    CGRect frame = self.frame;
    frame.origin.y = -self.frame.size.height;
    [self setFrame:frame];
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;
    [_loadingLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        [layer setBackgroundColor:_tintColor.CGColor];
    }];
}

//ios6-不会在table初始化时更改offset和inset，故_orignInsetTop和_orignOffsetY有可能还是CGFLOAT_MAX，需要加个判断
- (CGFloat)orignInsetTop
{
    if (_orignInsetTop>1000000.0) {
        _orignInsetTop = 0;
    }
    return _orignInsetTop;
}


#pragma mark - private method
- (void)setup
{
    _reachedEndLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _reachedEndLabel.backgroundColor = [UIColor clearColor];
    _reachedEndLabel.font = [UIFont systemFontOfSize:15.0];
    _reachedEndLabel.textColor = self.tintColor;
    _reachedEndLabel.textAlignment = NSTextAlignmentCenter;
    _reachedEndLabel.text = @"没有了";
    _reachedEndLabel.hidden = YES;
    [self addSubview:_reachedEndLabel];
    
    _loadingLayers = [NSMutableArray array];
    CGFloat w = self.frame.size.height*7/16;

    _loadingContainer = [[CALayer alloc] init];
    _loadingContainer.frame = CGRectMake(0, 0, w, w);
    _loadingContainer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self.layer addSublayer:_loadingContainer];
    
    
    for (int i=0; i<12; i++)
    {
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = _tintColor.CGColor;
        layer.frame = CGRectMake(w/2-1, w/2-w*2/7, 2, w*2/7);
        layer.anchorPoint = CGPointMake(0.5, 1+3/4.0);
        layer.allowsEdgeAntialiasing = YES;
        layer.cornerRadius = 1.0f;
        layer.transform = CATransform3DMakeRotation(M_PI*i/6, 0, 0, 1);
        [_loadingContainer addSublayer:layer];
        [_loadingLayers addObject:layer];
    }
}

- (void)beginLoading {
    _reachedEndLabel.hidden = YES;
    [_loadingLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        
        CAAnimation *animation = [self animationAtIndex:idx];
        [layer addAnimation:animation forKey:nil];
        layer.hidden = NO;
    }];
}

- (void)endLoading {
    
    [_loadingLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        
        [layer removeAllAnimations];
        layer.hidden = YES;
    }];
}

- (CAAnimation *)animationAtIndex:(NSInteger)index {
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = @(1);
    opacityAnimation.toValue = @(0);
    opacityAnimation.duration = 1;
    opacityAnimation.repeatCount = INFINITY;
    opacityAnimation.timeOffset = 1*(1 - index / 12.0);
    return opacityAnimation;
}






#pragma mark public method
- (void)addTarget:(UITableView *)target loadMoreAction:(SEL)action
{
    _target = target;
    _loadMoreAction = action;
    
    [target addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    [target addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeTarget:(UITableView *)target
{
    [target removeObserver:self forKeyPath:@"contentSize"];
    [target removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)finishLoading
{
    [self endLoading];
    if (_state == LoadMoreStateLoading) {
        _state = LoadMoreStateNormal;
    }
}

- (void)reachedEnd:(BOOL)reachedEnd
{
    if (reachedEnd) {
        _reachedEndLabel.hidden = NO;
        _state = LoadMoreStateReachEnd;
    }
    else
    {
        _reachedEndLabel.hidden = YES;
        _state = LoadMoreStateNormal;
    }
}






#define mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == _target) {
        if ([keyPath isEqualToString:@"contentSize"]) {
            CGFloat preContentHeight = [[change objectForKey:@"old"] CGSizeValue].height;
            CGFloat curContentHeight = [[change objectForKey:@"new"] CGSizeValue].height;
            if (preContentHeight == curContentHeight) {
                return;
            }
            
            CGRect frame = self.frame;
            if (!_isTop) { //底部加载更多，则需要每次加载完更新位置
                CGSize contentSize = _target.contentSize;
                frame.origin.y = contentSize.height < _target.frame.size.height ? _target.frame.size.height : contentSize.height;
            }
            self.frame = frame;
            
            if (_isTop) { //为了加载后不抖动
                
                if (curContentHeight-preContentHeight>0) {
                    CGPoint offset = _target.contentOffset;
                    if (preContentHeight == 0) {
                        offset.y = curContentHeight>_target.frame.size.height?(curContentHeight-_target.frame.size.height):0;
                    }
                    if (preContentHeight > 0)
                    {
                        offset.y += curContentHeight-preContentHeight;
                    }
                    if (_isReachedEnd) { //防止到底时抖动
                        offset.y -= _target.frame.size.height;
                    }
                    _target.contentOffset = offset;
                }
            }
        } else if ([keyPath isEqualToString:@"contentOffset"]) {
            // table在透明和不透明，初始contentOffset不一样
            if (_orignOffsetY > 1000000.0) {
                self.orignOffsetY = _target.contentOffset.y;
                
                //offset监听到时，inset可能还未初始化，不能将origninsetTop=_target.contentInset.top，而初始时table的contentOffset.y值和contentInset.top值正好相反
                self.orignInsetTop = -_target.contentOffset.y;
                
                //必须是顶部加载更多，才初始开始加载，只有ios7+才能触发，ios6中不会在table显示的时候改变contentOffset和inset
                if (_isTop && _autoLoadMore) {
                    _target.contentOffset = CGPointMake(0, _orignOffsetY-self.frame.size.height);
                }
            } else {
                [self tableViewDidScroll];
            }
        }
    }
}

- (void)tableViewDidScroll {
    if (_state == LoadMoreStateReachEnd || _state == LoadMoreStateLoading) {
        return;
    }
    CGPoint offset = _target.contentOffset;
    offset.y -= _orignOffsetY;
    
    CGSize size = _target.frame.size;
    CGSize contentSize = _target.contentSize;
    if (contentSize.height < _target.frame.size.height) {
        contentSize.height = _target.frame.size.height;
    }
    
    if (_isTop) {
        
        if (offset.y < 0) {
            _state = LoadMoreStateLoading;
            [self beginLoading];
            if (_target && [_target respondsToSelector:_loadMoreAction])
            {
                ((void (*)(id, SEL))[_target methodForSelector:_loadMoreAction])(_target, _loadMoreAction);
            }
            [UIView animateWithDuration:0.1 animations:^{
                _target.contentInset = UIEdgeInsetsMake(self.frame.size.height+self.orignInsetTop, 0, 0, 0);
            }];
        }
    } else {
        
        float yMargin = _target.contentOffset.y + size.height - contentSize.height;
        
        if ( yMargin > 0) {  //footer will appeared
            
            _state = LoadMoreStateLoading;
            [self beginLoading];
            if (_target && [_target respondsToSelector:_loadMoreAction])
            {
                ((void (*)(id, SEL))[_target methodForSelector:_loadMoreAction])(_target, _loadMoreAction);
            }
            
            [UIView animateWithDuration:0.1 animations:^{
                _target.contentInset = UIEdgeInsetsMake(self.orignInsetTop, 0, self.frame.size.height, 0);
            }];
        }
    }
}

@end
