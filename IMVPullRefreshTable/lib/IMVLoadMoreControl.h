//
//  IMVLoadingControl.h
//  IMVPullRefreshTable
//
//  Created by 陈少华 on 15/5/29.
//  Copyright (c) 2015年 inmovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMVLoadMoreControl : UIView

@property (assign, nonatomic) BOOL isTop;
@property (strong, nonatomic) UIColor *tintColor;
@property (strong, nonatomic) NSString *reachedEndText;

- (void)finishLoading;
- (void)reachedEnd;
- (void)addTarget:(UITableView *)target loadMoreAction:(SEL)action;
- (void)removeTarget:(UITableView *)target;

@end
