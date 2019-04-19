//
//  ZZTabViewBar.h
//  ZZTabViewBar
//
//  Created by Jungle on 2019/4/19.
//  Copyright (c) 2019. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>

/* 指示器类型 */
typedef NS_ENUM(NSInteger, ZZTabViewBarIndicatorType) {
    ZZTabViewBarIndicatorTypeImage,       // 图片
    ZZTabViewBarIndicatorTypeLine         // 底线（暂不支持）
};

/* 红点类型 */
typedef NS_ENUM(NSInteger, ZZTabViewBarRedPointType) {
    ZZTabViewBarRedPointTypeSolid,        // 实心红点
    ZZTabViewBarRedPointTypeHollow        // 空心红点
};

NS_ASSUME_NONNULL_BEGIN

@class ZZTabViewBar;
@protocol ZZTabViewBarDelegate <NSObject>
@required
/* 个数 */
- (NSInteger)numberOfItemsInTabViewBar:(ZZTabViewBar *)tabViewBar;
/* 标题 */
- (NSString *)tabViewBar:(ZZTabViewBar *)tabViewBar titleForItemAtIndex:(NSInteger)index;

@optional
/* 将要选中 */
- (void)tabViewBar:(ZZTabViewBar *)tabViewBar shouldSelectItemAtIndex:(NSInteger)index;
/* 选中 */
- (void)tabViewBar:(ZZTabViewBar *)tabViewBar didSelectItemAtIndex:(NSInteger)index;

@end

@interface ZZTabViewBar : UIView

// 默认文字颜色
@property (nonatomic, strong) UIColor *normalColor;
// 选中文字颜色
@property (nonatomic, strong) UIColor *selectedColor;
// 默认文字字体
@property (nonatomic, strong) UIFont *normalFont;
// 选中文字字体
@property (nonatomic, strong) UIFont *selectedFont;
// 指示器图片 `indicatorType = ZZTabViewBarIndicatorTypeImage时生效`
@property (nonatomic, strong) UIImage *indicatorImage;
// 文字与底部间距
@property (nonatomic, assign) CGFloat titleToBottomInterval;
// 指示器与底部间距
@property (nonatomic, assign) CGFloat indicatorToBottomInterval;
// 指示器高度
@property (nonatomic, assign) CGFloat indicatorHeight;
// tab与tab间距
@property (nonatomic, assign) CGFloat itemSpace;
// 指示器类型，默认图片类型
@property (nonatomic, assign) ZZTabViewBarIndicatorType indicatorType;
// 红点类型
@property (nonatomic, assign) ZZTabViewBarRedPointType redPointType;
// 默认选中TabIndex
@property (nonatomic, assign) NSInteger defaultSelectedIndex;
// ZZTabViewBarDelegate
@property (nonatomic, weak) id<ZZTabViewBarDelegate>delegate;

/* 重载TabViewBar数据 */
- (void)reloadTabViewBar;

/* TabViewBar滚动至指定index */
- (void)tabViewBarScrollToIndex:(NSInteger)index;

/* TabViewBar滚动中渐变效果 */
- (void)tabViewBarScrollFromStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex progress:(CGFloat)progress;

/* 展示红点 */
- (void)showRedPoint:(NSInteger)count index:(NSInteger)index;

/**
 暂只支持加入底部阴影
 
 @param shadowColor shadowColor
 @param shadowHeight shadowHeight
 */
- (void)showShadowWithColor:(UIColor *)shadowColor shadowHeight:(CGFloat)shadowHeight;

@end

NS_ASSUME_NONNULL_END
