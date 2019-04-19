//
//  ZZTabMutiPage.h
//  ZZTabViewBar
//
//  Created by Jungle on 2019/4/19.
//  Copyright (c) 2019. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ZZTabMutiPage;

@protocol ZZTabMutiPageDataSource <NSObject>
@required
/* 父视图 */
- (UIViewController *)parentVCForMutiPage:(ZZTabMutiPage *)mutiPage;
/* 个数 */
- (NSInteger)numberOfChildVCsInMutiPage:(ZZTabMutiPage *)mutiPage;
/* VC */
- (UIViewController *)mutiPage:(ZZTabMutiPage *)mutiPage childVCAtIndex:(NSInteger)index;

@optional
/* 子VC display */
- (void)mutiPage:(ZZTabMutiPage *)mutiPage willDisplayChildVC:(UIViewController *)childVC;
/* 子VC didEndDisplaying */
- (void)mutiPage:(ZZTabMutiPage *)mutiPage didEndDisplayingChildVC:(UIViewController *)childVC;

@end

@protocol ZZTabMutiPageDelegate <NSObject>
@optional
/* mutiPage 开始滑动 */
- (void)mutiPageWillBeginDragging:(ZZTabMutiPage *)mutiPage;
/* mutiPage 滑动中 */
- (void)mutiPageDidScroll:(ZZTabMutiPage *)mutiPage startIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex progress:(CGFloat)progress;
/* mutiPage 结束滑动 */
- (void)mutiPageDidEndDecelerating:(ZZTabMutiPage *)mutiPage;
/* mutiPage 滑动选中 */
- (void)mutiPage:(ZZTabMutiPage *)mutiPage selectedItemAtIndex:(NSInteger)index;

@end

@interface ZZTabMutiPage : UIView

@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, strong, readonly) UIViewController *currentChildVC;/* 当前展示的页面 */

@property (nonatomic, weak) id<ZZTabMutiPageDataSource>dataSource;
@property (nonatomic, weak) id<ZZTabMutiPageDelegate>delegate;

/* 默认0.5（即滚动超过了半屏，就认为翻页了）。范围0~1，开区间不包括0和1 */
@property (nonatomic, assign) CGFloat didAppearPercent;
/* 设置mutiPage当前展示的页面索引，默认为0 */
@property (nonatomic, assign) NSInteger currentIndex;
/* 默认YES（即能左右横滑）*/
@property (nonatomic, assign) BOOL mutiPageScrollEnabled;

/* 重载分页数据 */
- (void)reloadMutiPage;

@end

NS_ASSUME_NONNULL_END
