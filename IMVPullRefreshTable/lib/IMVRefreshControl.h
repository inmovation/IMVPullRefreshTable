//
//  IMVRefreshView.h
//  IMVPullRefreshTable
//
//  Created by 陈少华 on 15/5/28.
//  Copyright (c) 2015年 inmovation. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IMVRefreshControl : UIView

@property (assign, nonatomic) BOOL isRefreshing;
@property (strong, nonatomic) UIColor *tintColor;

- (void)addTarget:(UITableView *)target refreshAction:(SEL)action;
- (void)finishRefreshing;
- (void)removeTarget:(UITableView *)target;

@end
