//
//  IMVRefreshView.m
//  IMVPullRefreshTable
//
//  Created by 陈少华 on 15/5/28.
//  Copyright (c) 2015年 inmovation. All rights reserved.
//

#import "IMVRefreshControl.h"

typedef enum {
    RefreshStateNormal = 0,
    RefreshStatePullToRefresh,
    RefreshStateReleaseToRefresh,
    RefreshStateRefreshing
} RefreshState;


#define RefreshLayerCount 12
#define RefreshContainerRatio (7.0/16)
#define RefreshLayerRatio (4.0/7)

NSString* kRotationAnimation = @"RotationAnimation";

@interface IMVRefreshControl ()

@property (weak, nonatomic) UITableView *target;
@property (assign, nonatomic) SEL refreshAction;

@property (assign, nonatomic) CGFloat orignInsetTop;
@property (assign, nonatomic) CGFloat orignOffsetY;
@property (assign, nonatomic) RefreshState state;

@property (assign, nonatomic) BOOL isRotating;

@property (strong, nonatomic) CALayer *refreshContainer;
@property (strong, nonatomic) NSMutableArray *refreshLayers;
@property (assign, nonatomic) BOOL isRefreshingAnimation;

//如果需要自定义，新建子类并重写这几个方法
- (void)setup;
- (void)willRefreshWithProgress:(CGFloat)progress;
- (void)beginRefreshing;
- (void)endRefreshing;

@end

@implementation IMVRefreshControl

@synthesize tintColor = _tintColor;

- (instancetype)init
{
    self = [self initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 60)];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _orignInsetTop = CGFLOAT_MAX;
        _orignOffsetY = CGFLOAT_MAX;
        _tintColor = [UIColor colorWithWhite:110.0/255 alpha:1.0];
        _autoRefresh = YES;
        [self setup];
    }
    return self;
}


#pragma mark - getter setter
- (void)setTintColor:(UIColor *)tintColor{
    _tintColor = tintColor;
    [_refreshLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        layer.backgroundColor = tintColor.CGColor;
    }];
}

- (void)setOrignInsetTop:(CGFloat)orignInsetTop
{
    _orignInsetTop = orignInsetTop;
    CGRect frame = self.frame;
    frame.origin.y = _orignInsetTop;
    self.frame = frame;
}



#pragma mark - private method
- (void)setup
{
    _refreshLayers = [NSMutableArray array];
    CGFloat w = self.frame.size.height*RefreshContainerRatio;

    _refreshContainer = [[CALayer alloc] init];
    _refreshContainer.frame = CGRectMake(0, 0, w, w);
    _refreshContainer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    [self.layer addSublayer:_refreshContainer];
    
    for (int i=0; i<RefreshLayerCount; i++) {
        
        CALayer *layer = [[CALayer alloc] init];
        layer.backgroundColor = _tintColor.CGColor;
        layer.frame = CGRectMake(0, 0, 2, (w/2)*RefreshLayerRatio);
        layer.anchorPoint = CGPointMake(0.5, 1+(1-RefreshLayerRatio)/RefreshLayerRatio);
        layer.position = CGPointMake(w/2, w/2);
        layer.allowsEdgeAntialiasing = YES;
        layer.cornerRadius = 1.0f;
        layer.hidden = YES;
        layer.transform = CATransform3DMakeRotation(2*M_PI*i/RefreshLayerCount, 0, 0, 1);
        [_refreshContainer addSublayer:layer];
        [_refreshLayers addObject:layer];
    }
}

- (void)willRefreshWithProgress:(CGFloat)progress
{
    if (progress < 1/RefreshLayerCount) {
        return;
    }
    else if (progress>0 && progress<1) {
        _isRotating = NO;
        [_refreshContainer removeAllAnimations];
    }
    else
    {
        if (!_isRotating) {
            _isRotating = YES;
            [_refreshContainer removeAllAnimations];
            [_refreshContainer addAnimation:[self rotationAnimation] forKey:nil];
        }
    }
    CGFloat w = self.frame.size.height*RefreshContainerRatio;
    _refreshContainer.frame = CGRectMake(0, 0, w, w);
    _refreshContainer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    for (int i=1; i<=RefreshLayerCount; i++) {
        CALayer *layer = _refreshLayers[i-1];
        if (i <= progress * RefreshLayerCount) {
            layer.hidden = NO;
        }else{
            layer.hidden = YES;
        }
    }
}

- (void)beginRefreshing
{
    _isRotating = NO;
    _isRefreshing = YES;
    [_refreshContainer removeAllAnimations];
    [_refreshLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        [layer addAnimation:[self opacityAnimationAtIndex:idx] forKey:@"opacity"];
    }];
}

- (void)endRefreshing
{
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [_refreshLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
            [layer removeAllAnimations];
            layer.hidden = YES;
        }];
    }];
    [_refreshContainer removeAllAnimations];
    [_refreshLayers enumerateObjectsUsingBlock:^(CALayer *layer, NSUInteger idx, BOOL *stop) {
        [layer removeAnimationForKey:@"opacity"];
        [layer addAnimation:[self sizeAnimation] forKey:nil];
        [layer addAnimation:[self rotationAnimationAtIndex:idx] forKey:nil];
    }];
    
    [CATransaction commit];
}


- (CAAnimation *)rotationAnimation {
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:0];
    rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI];
    rotationAnimation.duration = 0.5f;
    rotationAnimation.repeatCount = INFINITY;
    rotationAnimation.speed = 0.5f;
    return rotationAnimation;
}

- (CAAnimation *)opacityAnimationAtIndex:(NSInteger)index {
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = @(1);
    opacityAnimation.toValue = @(0);
    opacityAnimation.duration = 1;
    opacityAnimation.repeatCount = INFINITY;
    opacityAnimation.timeOffset = 1*(1 - index*1.0/RefreshLayerCount);
    return opacityAnimation;
}

- (CAAnimation *)sizeAnimation {
    CABasicAnimation *sizeAnimation = [CABasicAnimation animationWithKeyPath:@"bounds.size.height"];
    sizeAnimation.fromValue = [NSNumber numberWithFloat:(self.frame.size.height*RefreshContainerRatio/2)*RefreshLayerRatio];
    sizeAnimation.toValue = [NSNumber numberWithFloat:0];
    sizeAnimation.duration = 0.25f;
    sizeAnimation.repeatCount = 0;
    sizeAnimation.removedOnCompletion = NO;
    sizeAnimation.fillMode = kCAFillModeForwards;
    return sizeAnimation;
}

- (CAAnimation *)rotationAnimationAtIndex:(NSInteger)index {
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotationAnimation.fromValue = [NSNumber numberWithFloat:2*M_PI*index/RefreshLayerCount];
    rotationAnimation.toValue = [NSNumber numberWithFloat:2*M_PI*index/RefreshLayerCount+M_PI/2];
    rotationAnimation.duration = 0.25f;
    rotationAnimation.repeatCount = 0;
    rotationAnimation.removedOnCompletion = YES;
    return rotationAnimation;
}







#pragma mark - public method
- (void)addTarget:(UITableView *)target refreshAction:(SEL)action
{
    _target = target;
    _refreshAction = action;
    
    [target addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeTarget:(UITableView *)target
{
    [target removeObserver:self forKeyPath:@"contentOffset"];
}

- (void)refresh
{
    CGFloat offY = _orignOffsetY-self.frame.size.height-self.frame.size.height*(1-RefreshContainerRatio)/2;
    _target.contentOffset = CGPointMake(0, offY);
    [self tableViewDidScroll];
}

- (void)finishRefreshing
{
    [self endRefreshing];
    _isRefreshing = NO;
    _state = RefreshStateNormal;
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        UIEdgeInsets inset = _target.contentInset;
        inset.top = _orignInsetTop;
        _target.contentInset = inset;
    } completion:nil];
}





#define mark - kvo
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == _target) {
        if ([keyPath isEqualToString:@"contentOffset"]) {

            // table在透明和不透明，初始contentOffset不一样
            if (_orignOffsetY > 1000000.0) {
                self.orignOffsetY = _target.contentOffset.y;
                
                //offset监听到时，inset可能还未初始化，不能将origninsetTop=_target.contentInset.top，而初始时table的contentOffset.y值和contentInset.top值正好相反
                self.orignInsetTop = -_target.contentOffset.y;
                
                //初始刷新，只有ios7+才能触发，ios6中不会在table显示的时候改变contentOffset和inset
                if (_autoRefresh) {
                    _target.contentOffset = CGPointMake(0, _orignOffsetY-self.frame.size.height-self.frame.size.height*(1-RefreshContainerRatio)/2);
                }
                return;
            }
            else
            {
                [self tableViewDidScroll];
                if (!_target.isDragging && _state == RefreshStateReleaseToRefresh) {
                    [self tableViewDidEndDragging];
                }
            }
        }
    }
}

- (void)tableViewDidScroll
{
    if (_state == RefreshStateRefreshing) {
        return;
    }
    CGPoint offset = _target.contentOffset;
    offset.y -= _orignOffsetY;
    
    offset.y += self.frame.size.height*(1-RefreshContainerRatio)/2;
    
    if (offset.y < 0 && offset.y > -self.frame.size.height){ //header part appeared
        _state = RefreshStatePullToRefresh;
        [self willRefreshWithProgress:fabs(offset.y)/self.frame.size.height];
        
    } else if (offset.y <= -self.frame.size.height) {   //header totally appeard
        _state = RefreshStateReleaseToRefresh;
        [self willRefreshWithProgress:fabs(offset.y)/self.frame.size.height];
    }
}

- (void)tableViewDidEndDragging
{
    if (_state != RefreshStateReleaseToRefresh) {
        return;
    }
    _isRefreshing = YES;
    _state = RefreshStateRefreshing;
    [self beginRefreshing];
    if (_target && [_target respondsToSelector:_refreshAction])
    {
        ((void (*)(id, SEL))[_target methodForSelector:_refreshAction])(_target, _refreshAction);
    }
    
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        UIEdgeInsets inset = _target.contentInset;
        
        inset.top = self.frame.size.height+_orignInsetTop;
        _target.contentInset = inset;
    } completion:nil];
}

@end