//
//  ZZTabViewBar.m
//  ZZTabViewBar
//
//  Created by Jungle on 2019/4/19.
//  Copyright (c) 2019. All rights reserved.
//

#import "ZZTabViewBar.h"

#define ZZTABVIEWBAR_UPDATE_FRAME(target, value) CGRect rect = self.frame; rect.target = value; self.frame = rect;
#define ZZTABVIEWBAR_UPDATE_CENTER(target, value) CGPoint center = self.center; center.target = value; self.center = center;

@implementation UIView (ZZTabViewBarFrame)

- (CGFloat)x {
    return self.frame.origin.x;
}

- (void)setX:(CGFloat)x {
    ZZTABVIEWBAR_UPDATE_FRAME(origin.x, x);
}

- (CGFloat)y {
    return self.frame.origin.y;
}

- (void)setY:(CGFloat)y {
    ZZTABVIEWBAR_UPDATE_FRAME(origin.y, y);
}

- (CGPoint)xy {
    return self.frame.origin;
}

- (void)setXy:(CGPoint)xy {
    ZZTABVIEWBAR_UPDATE_FRAME(origin, xy);
}

- (CGFloat)w {
    return self.frame.size.width;
}

- (void)setW:(CGFloat)width {
    ZZTABVIEWBAR_UPDATE_FRAME(size.width, width);
}

- (CGFloat)h {
    return self.frame.size.height;
}

- (void)setH:(CGFloat)height {
    ZZTABVIEWBAR_UPDATE_FRAME(size.height, height);
}

- (CGSize)wh {
    return self.frame.size;
}

- (void)setWh:(CGSize)size {
    ZZTABVIEWBAR_UPDATE_FRAME(size, size);
}

- (CGFloat)cx {
    return self.center.x;
}

- (void)setCx:(CGFloat)cx {
    ZZTABVIEWBAR_UPDATE_CENTER(x, cx);
}

- (CGFloat)cy {
    return self.center.y;
}

- (void)setCy:(CGFloat)cy {
    ZZTABVIEWBAR_UPDATE_CENTER(y, cy);
}

- (CGFloat)maxX {
    return CGRectGetMaxX(self.frame);
}

- (void)setMaxX:(CGFloat)maxX {
    ZZTABVIEWBAR_UPDATE_FRAME(origin.x, maxX - rect.size.width);
}

- (CGFloat)maxY {
    return CGRectGetMaxY(self.frame);
}

- (void)setMaxY:(CGFloat)maxY {
    ZZTABVIEWBAR_UPDATE_FRAME(origin.y, maxY - rect.size.height);
}

- (CGPoint)maxXY {
    return CGPointMake(CGRectGetMaxX(self.frame), CGRectGetMaxY(self.frame));
}

- (void)setMaxXY:(CGPoint)maxXY {
    ZZTABVIEWBAR_UPDATE_FRAME(origin, CGPointMake(maxXY.x - rect.size.width, maxXY.y - rect.size.height));
}

- (CGPoint)midPoint {
    return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

@end

@implementation UIColor (ZZTabViewBarHex)

+ (UIColor *)colorWithHexString:(NSString *)color alpha:(CGFloat)alpha {
    //删除字符串中的空格
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    // strip 0X if it appears
    //如果是0x开头的，那么截取字符串，字符串从索引为2的位置开始，一直到末尾
    if ([cString hasPrefix:@"0X"]) {
        cString = [cString substringFromIndex:2];
    }
    //如果是#开头的，那么截取字符串，字符串从索引为1的位置开始，一直到末尾
    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    }
    if ([cString length] != 6) {
        return [UIColor clearColor];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

//默认alpha值为1
+ (UIColor *)colorWithHexString:(NSString *)color {
    return [self colorWithHexString:color alpha:1.0f];
}

@end

static CGFloat const kTabViewBarRedPointWidth = 16.0f;
static CGFloat const kTabViewBarRedPointToTitleX = 6.0f;
static CGFloat const kTabViewBarRedPointToTitleY = 9.0f;
static CGFloat const kTabViewBarRedPointFontSize = 11.0f;

static NSString * const kTabViewBarTabViewBarItemReusedId = @"kTabViewBarTabViewBarItemReusedId";

static inline CGSize kTabViewBarTabTitleSize(NSString *title, UIFont *font) {
    NSDictionary *attrs = @{NSFontAttributeName : font};
    return [title boundingRectWithSize:CGSizeZero options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs context:nil].size;
}

@interface ZZTabViewBarItem : UICollectionViewCell

@property (nonatomic, assign) ZZTabViewBarRedPointType redPointType;
@property (nonatomic, strong) UIColor                   *normalColor;
@property (nonatomic, strong) UIColor                   *selectedColor;
@property (nonatomic, strong) UIFont                    *normalFont;
@property (nonatomic, strong) UIFont                    *selectedFont;
@property (nonatomic, assign) CGSize                    normalSize;
@property (nonatomic, assign) CGSize                    selectedSize;
@property (nonatomic, assign) CGFloat                   widthScale;
@property (nonatomic, assign) CGFloat                   heightScale;
@property (nonatomic, strong) UILabel                   *titleLabel;
@property (nonatomic, strong) UILabel                   *redPointLabel;
@property (nonatomic, assign) CGFloat                   titleToBottomInterval;
@property (nonatomic, assign) BOOL                      isTaped;

@end

@implementation ZZTabViewBarItem

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.titleLabel];
        [self addSubview:self.redPointLabel];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.redPointLabel.hidden = YES;
    self.titleLabel.transform = CGAffineTransformIdentity;
}

- (void)resetTitleFrame {
    self.titleLabel.textColor = self.normalColor;
    self.titleLabel.font = self.selectedFont;
    CGRect frame = CGRectMake((self.w-self.selectedSize.width)/2.0, self.h-self.titleToBottomInterval-self.selectedSize.height, self.selectedSize.width, self.selectedSize.height);
    self.titleLabel.frame = frame;
    // 再由大frame缩放为小frame，防止字体模糊
    CGAffineTransform scale = CGAffineTransformMakeScale(self.widthScale, self.heightScale);
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, (1.0-self.heightScale)/2.0*self.selectedSize.height);
    self.titleLabel.transform = CGAffineTransformConcat(scale, translate);
    self.redPointLabel.frame = CGRectMake(self.titleLabel.maxX-kTabViewBarRedPointToTitleX, self.titleLabel.y-kTabViewBarRedPointToTitleY, kTabViewBarRedPointWidth, kTabViewBarRedPointWidth);
}

// 渐变（选中->未选中）
- (void)scaleStartIndexWithProgress:(CGFloat)progress {
    CGFloat scaleW = 1.0-(1.0-self.widthScale)*progress;
    CGFloat scaleH = 1.0-(1.0-self.heightScale)*progress;
    CGAffineTransform scale = CGAffineTransformMakeScale(scaleW, scaleH);
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, (1.0-scaleH)/2.0*self.selectedSize.height);
    self.titleLabel.transform = CGAffineTransformConcat(scale, translate);
    self.redPointLabel.x = self.titleLabel.maxX-kTabViewBarRedPointToTitleX;
}

// 渐变（未选中->选中）
- (void)scaleEndIndexWithProgress:(CGFloat)progress {
    CGFloat scaleW = self.widthScale+(1.0-self.widthScale)*progress;
    CGFloat scaleH = self.heightScale+(1.0-self.heightScale)*progress;
    CGAffineTransform scale = CGAffineTransformMakeScale(scaleW, scaleH);
    CGAffineTransform translate = CGAffineTransformMakeTranslation(0, (1.0-scaleH)/2.0*self.normalSize.height);
    self.titleLabel.transform = CGAffineTransformConcat(scale, translate);
    self.redPointLabel.x = self.titleLabel.maxX-kTabViewBarRedPointToTitleX;
}

#pragma mark - Setter

- (void)setItemTitle:(NSString *)itemTitle {
    self.titleLabel.textColor = self.selectedColor;
    self.titleLabel.font = self.selectedFont;
    self.titleLabel.text = itemTitle;
}

// 状态改变（选中/未选中）
- (void)setIsTaped:(BOOL)isTaped {
    _isTaped = isTaped;
    if (isTaped) {
        self.titleLabel.transform = CGAffineTransformIdentity;
        self.titleLabel.textColor = self.selectedColor;
        self.redPointLabel.x = self.titleLabel.maxX-kTabViewBarRedPointToTitleX;
    } else {
        CGAffineTransform scale = CGAffineTransformMakeScale(self.widthScale, self.heightScale);
        CGAffineTransform translate = CGAffineTransformMakeTranslation(0, (1.0-self.heightScale)/2.0*self.selectedSize.height);
        self.titleLabel.transform = CGAffineTransformConcat(scale, translate);
        self.titleLabel.textColor = self.normalColor;
        self.redPointLabel.x = self.titleLabel.maxX-kTabViewBarRedPointToTitleX;
    }
}

- (void)setRedPointType:(ZZTabViewBarRedPointType)redPointType {
    _redPointType = redPointType;
    self.redPointLabel.layer.backgroundColor = redPointType == ZZTabViewBarRedPointTypeSolid ? UIColor.redColor.CGColor : UIColor.clearColor.CGColor;
    self.redPointLabel.textColor = redPointType == ZZTabViewBarRedPointTypeSolid ? UIColor.whiteColor : UIColor.redColor;
    self.redPointLabel.layer.borderColor = redPointType == ZZTabViewBarRedPointTypeSolid ? UIColor.whiteColor.CGColor : UIColor.redColor.CGColor;
}

#pragma mark - Getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor grayColor];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    }
    return _titleLabel;
}

- (UILabel *)redPointLabel {
    if (!_redPointLabel) {
        _redPointLabel = [UILabel new];
        _redPointLabel.textColor = UIColor.whiteColor;
        _redPointLabel.textAlignment = NSTextAlignmentCenter;
        _redPointLabel.font = [UIFont systemFontOfSize:kTabViewBarRedPointFontSize];
        _redPointLabel.layer.backgroundColor = [UIColor colorWithHexString:@"FF5151"].CGColor;
        _redPointLabel.layer.cornerRadius = kTabViewBarRedPointWidth/2.0;
        _redPointLabel.layer.borderWidth = 1.0;
        _redPointLabel.layer.masksToBounds = YES;
        _redPointLabel.hidden = YES;
    }
    return _redPointLabel;
}

@end

@interface ZZTabViewBar ()<UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UICollectionView      *collectionView;
@property (nonatomic, strong) UIImageView           *indicatorView;
@property (nonatomic, assign) NSInteger             currentIndex;
@property (nonatomic, assign) BOOL                  clipForShadow;
@property (nonatomic, strong) NSMutableArray        *titleList;
@property (nonatomic, strong) NSMutableArray        *redPointNumList;
@property (nonatomic, strong) NSMutableArray        *normalSizeList;
@property (nonatomic, strong) NSMutableArray        *selectedSizeList;
@property (nonatomic, strong) NSMutableArray        *widthScaleList;
@property (nonatomic, strong) NSMutableArray        *heightScaleList;
@property (nonatomic, strong) NSMutableArray        *itemSizeList;

@end

@implementation ZZTabViewBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupDefaults];
        [self addSubview:self.indicatorView];
        [self addSubview:self.collectionView];
    }
    return self;
}

- (void)setupDefaults {
    _titleList = [NSMutableArray new];
    _redPointNumList = [NSMutableArray new];
    _normalSizeList = [NSMutableArray new];
    _selectedSizeList = [NSMutableArray new];
    _widthScaleList = [NSMutableArray new];
    _heightScaleList = [NSMutableArray new];
    _itemSizeList = [NSMutableArray new];
    _normalFont = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    _selectedFont = [UIFont systemFontOfSize:18.0f weight:UIFontWeightMedium];
    _normalColor = [UIColor colorWithHexString:@"#9B9B9B"];
    _selectedColor = [UIColor colorWithHexString:@"#111111"];
    _indicatorHeight = 8.0f;
    _titleToBottomInterval = 15.0f;
    _indicatorToBottomInterval = 15.0f;
    _itemSpace = 15.0f;
    _indicatorType = ZZTabViewBarIndicatorTypeImage;
    _indicatorImage = [UIImage imageNamed:@"tabViewBar_indicator_line"];
    _defaultSelectedIndex = -1;
    _currentIndex = -1;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.collectionView.frame = self.bounds;
}

#pragma mark - Public

- (void)reloadTabViewBar {
    if (!self.delegate) return;
    
    NSInteger numberOfItems = [self.delegate numberOfItemsInTabViewBar:self];
    [self reloadLists:numberOfItems];
    [self.collectionView reloadData];
    
    if (self.defaultSelectedIndex < numberOfItems) {
        self.currentIndex = self.defaultSelectedIndex;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            [self scrollToIndex:self.currentIndex];
        });
    }
}

- (void)tabViewBarScrollToIndex:(NSInteger)index {
    if (index < [self.delegate numberOfItemsInTabViewBar:self]) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self scrollToIndex:index];
    }
}

- (void)tabViewBarScrollFromStartIndex:(NSInteger)startIndex endIndex:(NSInteger)endIndex progress:(CGFloat)progress {
    // 左->右（startIndex < endIndex），progress：0->1.0
    // 右->左（endIndex < startIndex），progress：1.0->0
    if (endIndex < startIndex) { // 处理成一致，即progress：0->1.0
        progress = 1.0-progress;
    }
    ZZTabViewBarItem *startItem = (ZZTabViewBarItem *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:startIndex inSection:0]];
    ZZTabViewBarItem *endItem = (ZZTabViewBarItem *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:endIndex inSection:0]];
    [startItem scaleStartIndexWithProgress:progress];   // 缩小
    [endItem scaleEndIndexWithProgress:progress];       // 放大
    
    CGRect startRect = [self convertToIndicatorRect:startIndex];
    CGRect endRect = [self convertToIndicatorRect:endIndex];
    CGFloat minW = self.itemSpace * 1.5;
    if (endIndex > startIndex) {
        CGFloat minX = CGRectGetMaxX(startRect)/2.0 + CGRectGetMinX(endRect)/2.0 - minW/2.0;
        if (progress <= 0) {
            self.indicatorView.frame = startRect;
        } else if (progress > 0 && progress <= 0.5) { // 指示器变短
            CGFloat x = CGRectGetMinX(startRect) + (minX-CGRectGetMinX(startRect)) * progress * 2;
            CGFloat w = CGRectGetWidth(startRect) - (CGRectGetWidth(startRect) - minW) * progress * 2;
            CGRect frame = startRect;
            frame.origin.x = x;
            frame.size.width = w;
            self.indicatorView.frame = frame;
        } else if (progress > 0.5 && progress < 1.0) { // 指示器变长
            CGFloat x = minX + (CGRectGetMinX(endRect) - minX) * (progress * 2 - 1.0);
            CGFloat w = minW + (CGRectGetWidth(endRect) - minW) * (progress * 2 - 1.0);
            CGRect frame = startRect;
            frame.origin.x = x;
            frame.size.width = w;
            self.indicatorView.frame = frame;
        } else {
            self.indicatorView.frame = endRect;
        }
    } else if (endIndex < startIndex) {
        CGFloat minX = CGRectGetMaxX(endRect)/2.0 + CGRectGetMinX(startRect)/2.0 - minW/2.0;
        if (progress <= 0) {
            self.indicatorView.frame = startRect;
        } else if (progress > 0 && progress <= 0.5) { // 指示器变短
            CGFloat x = CGRectGetMinX(startRect) - (CGRectGetMinX(startRect) - minX) * progress * 2;
            CGFloat w = CGRectGetWidth(startRect) - (CGRectGetWidth(startRect) - minW) * progress * 2;
            CGRect frame = startRect;
            frame.origin.x = x;
            frame.size.width = w;
            self.indicatorView.frame = frame;
        } else if (progress > 0.5 && progress < 1.0) { // 指示器变长
            CGFloat x = minX - (minX-CGRectGetMinX(endRect)) * (progress * 2 - 1.0);
            CGFloat w = minW - (minW - CGRectGetWidth(endRect)) * (progress * 2 - 1.0);
            CGRect frame = startRect;
            frame.origin.x = x;
            frame.size.width = w;
            self.indicatorView.frame = frame;
        } else {
            self.indicatorView.frame = endRect;
        }
    } else if (endIndex == startIndex) {
        self.indicatorView.frame = startRect;
    }
}

- (void)showRedPoint:(NSInteger)count index:(NSInteger)index {
    ZZTabViewBarItem *cell = (ZZTabViewBarItem *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    if (count < 0) {
        count = 0;
    } else if (count > 99) {
        count = 99;
    }
    NSString *redPointNum = [NSString stringWithFormat:@"%zd", count];
    if (self.redPointNumList.count > 0 && index < self.redPointNumList.count) {
        [self.redPointNumList replaceObjectAtIndex:index withObject:redPointNum];
    }
    if (!cell) {
        return;
    }
    [self showRedPointWithCell:cell count:count index:index];
}

- (void)showShadowWithColor:(UIColor *)shadowColor shadowHeight:(CGFloat)shadowHeight {
    self.clipForShadow = YES;
    self.clipsToBounds = NO;
    self.layer.shadowOffset = CGSizeZero;
    self.layer.shadowColor = shadowColor.CGColor;
    self.layer.shadowRadius = 4;
    self.layer.shadowOpacity = .4f;
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, CGRectGetHeight(self.frame) - shadowHeight / 2, CGRectGetWidth(self.frame), shadowHeight)];
    self.layer.shadowPath = path.CGPath;
}

#pragma mark - Private

- (void)reloadLists:(NSInteger)numberOfItems {
    
    [self.titleList removeAllObjects];
    [self.redPointNumList removeAllObjects];
    [self.itemSizeList removeAllObjects];
    [self.normalSizeList removeAllObjects];
    [self.selectedSizeList removeAllObjects];
    [self.widthScaleList removeAllObjects];
    [self.heightScaleList removeAllObjects];
    
    for (NSInteger i = 0; i < numberOfItems; i ++) {
        NSString *title = [self.delegate tabViewBar:self titleForItemAtIndex:i]?:@"";
        CGSize normalSize = kTabViewBarTabTitleSize(title, self.normalFont);
        CGSize selectedSize = kTabViewBarTabTitleSize(title, self.selectedFont);
        CGFloat widthScale = selectedSize.width > 0 ? normalSize.width/selectedSize.width : 0;
        CGFloat heightScale = selectedSize.height > 0 ? normalSize.height/selectedSize.height : 0;
        CGFloat itemWidth = MAX(selectedSize.width+self.itemSpace/2.0, self.itemSpace*2.5+normalSize.width);
        CGSize itemSize = CGSizeMake(itemWidth, self.h);
        
        [self.titleList addObject:title];
        [self.redPointNumList addObject:@"0"];
        [self.itemSizeList addObject:@(itemSize)];
        [self.normalSizeList addObject:@(normalSize)];
        [self.selectedSizeList addObject:@(selectedSize)];
        [self.widthScaleList addObject:@(widthScale)];
        [self.heightScaleList addObject:@(heightScale)];
    }
}

- (void)scrollToIndex:(NSInteger)index {
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof ZZTabViewBarItem * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        if (indexPath.item != index) {
            cell.selected = NO;
        }
    }];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    self.currentIndex = index;
    [self.collectionView.visibleCells enumerateObjectsUsingBlock:^(__kindof ZZTabViewBarItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:item];
        if (indexPath.item != index) {
            item.isTaped = NO;
        } else {
            item.isTaped = YES;
        }
    }];
    CGRect indicatorRect = [self convertToIndicatorRect:index];
    [UIView animateWithDuration:0.2 animations:^{
        self.indicatorView.frame = indicatorRect;
    }];
}

- (CGRect)convertToIndicatorRect:(NSInteger)index {
    ZZTabViewBarItem *item = (ZZTabViewBarItem *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    CGRect convertRect =
    [item.contentView convertRect:item.titleLabel.frame toView:self];
    CGRect indicatorRect = CGRectMake(convertRect.origin.x-2.0, self.h-self.indicatorToBottomInterval-self.indicatorHeight, convertRect.size.width>0?(convertRect.size.width+4.0):0, self.indicatorHeight);
    return indicatorRect;
}

- (void)showRedPointWithCell:(ZZTabViewBarItem *)cell count:(NSInteger)count index:(NSInteger)index {
    NSString *redPointNum = [NSString stringWithFormat:@"%zd", count];
    if (count == 0) {
        cell.redPointLabel.text = redPointNum;
        cell.redPointLabel.hidden = YES;
    } else {
        CGFloat redPointW = kTabViewBarRedPointWidth;
        if (count > 9) {
            redPointW = 20.0f;
        }
        cell.redPointLabel.text = redPointNum;
        cell.redPointLabel.layer.cornerRadius = kTabViewBarRedPointWidth/2.0;
        cell.redPointLabel.w = redPointW;
        cell.redPointLabel.hidden = NO;
    }
}

#pragma  mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return [self.itemSizeList[indexPath.item] CGSizeValue];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, self.itemSpace/3.0, 0, self.itemSpace/3.0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.delegate numberOfItemsInTabViewBar:self];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZZTabViewBarItem *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTabViewBarTabViewBarItemReusedId forIndexPath:indexPath];
    cell.normalSize = [self.normalSizeList[indexPath.item] CGSizeValue];
    cell.selectedSize = [self.selectedSizeList[indexPath.item] CGSizeValue];
    cell.widthScale = [self.widthScaleList[indexPath.item] floatValue];
    cell.heightScale = [self.heightScaleList[indexPath.item] floatValue];
    cell.titleToBottomInterval = self.titleToBottomInterval;
    cell.normalColor = self.normalColor;
    cell.selectedColor = self.selectedColor;
    cell.normalFont = self.normalFont;
    cell.selectedFont = self.selectedFont;
    cell.redPointType = self.redPointType;
    [cell resetTitleFrame];
    [cell setItemTitle:self.titleList[indexPath.item]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    ZZTabViewBarItem *item = (ZZTabViewBarItem *)cell;
    if (self.currentIndex == indexPath.item) {
        item.isTaped = YES;
    } else {
        item.isTaped = NO;
    }
    NSString *redPointNum = self.redPointNumList[indexPath.item];
    [self showRedPointWithCell:item count:redPointNum.integerValue index:indexPath.item];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(tabViewBar:shouldSelectItemAtIndex:)]) {
        [self.delegate tabViewBar:self shouldSelectItemAtIndex:indexPath.item];
    }
    if (indexPath.item == self.currentIndex) {
        return NO;
    }
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    [self scrollToIndex:indexPath.item];
    if ([self.delegate respondsToSelector:@selector(tabViewBar:didSelectItemAtIndex:)]) {
        [self.delegate tabViewBar:self didSelectItemAtIndex:indexPath.item];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect indicatorRect = [self convertToIndicatorRect:self.currentIndex];
    self.indicatorView.frame = indicatorRect;
}

#pragma mark - Setter

- (void)setClipsToBounds:(BOOL)clipsToBounds {
    if (self.clipForShadow) {
        clipsToBounds = NO;
    }
    [super setClipsToBounds:clipsToBounds];
}

- (void)setIndicatorImage:(UIImage *)indicatorImage {
    _indicatorImage = indicatorImage;
    _indicatorView.image = indicatorImage;
}

#pragma mark - Getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.decelerationRate = 0.1f;
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.scrollsToTop = NO;
        [_collectionView registerClass:[ZZTabViewBarItem class] forCellWithReuseIdentifier:kTabViewBarTabViewBarItemReusedId];
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _collectionView;
}

- (UIImageView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.h-self.indicatorToBottomInterval-self.indicatorHeight, 40, self.indicatorHeight)];
        _indicatorView.layer.cornerRadius = self.indicatorHeight/2.0;
        _indicatorView.layer.masksToBounds = YES;
    }
    return _indicatorView;
}

@end
