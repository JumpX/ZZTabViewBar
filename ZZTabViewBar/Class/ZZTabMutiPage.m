//
//  ZZTabMutiPage.m
//  ZZTabViewBar
//
//  Created by Jungle on 2019/4/19.
//  Copyright (c) 2019. All rights reserved.
//

#import "ZZTabMutiPage.h"

@implementation NSArray (ZZTabMutiPageSafe)

- (id)vcSafeAtIndex:(NSInteger)index {
    if (self && index >= 0 && self.count > index) {
        return [self objectAtIndex:index];
    }
    return nil;
}

@end

static NSString * const ZZTabMutiPageCellIdentifier = @"ZZTabMutiPageCellIdentifier";

@interface ZZTabMutiPage ()<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong, readwrite) UICollectionView *collectionView;
@property (nonatomic, strong, readwrite) UIViewController *currentChildVC;
@property (nonatomic, weak)   UIViewController    *parentVC; // 父视图
@property (nonatomic, strong) NSArray             *childVCs; // 子视图数组
// 正在滚动中的目标index。用于处理正在滚动列表的时候，立即点击item，会导致界面显示异常。
@property (nonatomic, assign) NSInteger           scrollingTargetIndex;
@property (nonatomic, assign) CGPoint             lastContentOffset;

@end

@implementation ZZTabMutiPage

#pragma mark - Life Cycle

- (void)dealloc {
    if (_collectionView) {
        [_collectionView removeObserver:self forKeyPath:@"contentOffset"];
        _collectionView.delegate = nil;
        _collectionView.dataSource = nil;
    }
}

- (instancetype)init {
    if (self = [super init]) {
        _lastContentOffset = CGPointZero;
        _scrollingTargetIndex = -1;
        _didAppearPercent = 0.5;
        _mutiPageScrollEnabled = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.collectionView.frame = self.bounds;
}

#pragma mark - Public

- (void)reloadMutiPage {
    if (!self.dataSource) return;
    if (![self.dataSource respondsToSelector:@selector(parentVCForMutiPage:)]) return;
    if (![self.dataSource respondsToSelector:@selector(numberOfChildVCsInMutiPage:)]) return;
    if (self.childVCs && self.childVCs.count > 0) {
        for (int i = 0; i < self.childVCs.count; i ++) {
            UIViewController *childVC = [self.childVCs vcSafeAtIndex:i];
            if (childVC && childVC.parentViewController) {
                [childVC willMoveToParentViewController:nil];
                [childVC.view removeFromSuperview];
                [childVC removeFromParentViewController];
            }
        }
    }
    [self.collectionView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    
    self.parentVC = [self.dataSource parentVCForMutiPage:self];
    NSInteger count = [self.dataSource numberOfChildVCsInMutiPage:self];
    NSMutableArray *childVCs = [@[] mutableCopy];
    if ([self.dataSource respondsToSelector:@selector(mutiPage:childVCAtIndex:)]) {
        for (int i = 0; i < count; i ++) {
            UIViewController *viewController = [self.dataSource mutiPage:self childVCAtIndex:i];
            [childVCs addObject:viewController];
        }
    }
    self.childVCs = [childVCs copy];
    self.collectionView.frame = self.bounds;
    self.collectionView.contentSize = CGSizeMake(self.bounds.size.width*self.childVCs.count, self.bounds.size.height);
    [self.collectionView reloadData];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        if ((self.collectionView.isTracking || self.collectionView.isDecelerating)) {
            //只处理用户滚动的情况
            [self mutiPageDidChangedContentOffset:contentOffset];
        }
        self.lastContentOffset = contentOffset;
    }
}

- (void)mutiPageDidChangedContentOffset:(CGPoint)contentOffset {
    CGFloat ratio = contentOffset.x/self.collectionView.bounds.size.width;
    if (ratio > self.childVCs.count - 1 || ratio < 0) {
        //超过了边界，不需要处理
        return;
    }
    if (contentOffset.x == 0 && self.currentIndex == 0 && self.lastContentOffset.x == 0) {
        //滚动到了最左边，且已经选中了第一个，且之前的contentOffset.x为0
        return;
    }
    CGFloat maxContentOffsetX = self.collectionView.contentSize.width - self.collectionView.bounds.size.width;
    if (contentOffset.x == maxContentOffsetX &&
        self.currentIndex == self.childVCs.count - 1 &&
        self.lastContentOffset.x == maxContentOffsetX) {
        //滚动到了最右边，且已经选中了最后一个，且之前的contentOffset.x为maxContentOffsetX
        return;
    }
    ratio = MAX(0, MIN(self.childVCs.count - 1, ratio));
    NSInteger baseIndex = floorf(ratio);
    CGFloat remainderRatio = ratio - baseIndex;
    
    if (remainderRatio == 0) {
        //快速滑动翻页，用户一直在拖拽collectionView，需要更新选中状态
        //滑动一小段距离，然后放开回到原位，contentOffset同样的值会回调多次。例如在index为1的情况，滑动放开回到原位，contentOffset会多次回调CGPoint(width, 0)
        if (!(self.lastContentOffset.x == contentOffset.x && self.currentIndex == baseIndex)) {
            [self scrollSelectItemAtIndex:baseIndex];
        }
    } else {
        //快速滑动翻页，当remainderRatio没有变成0，但是已经翻页了，需要通过下面的判断，触发选中
        if (fabs(ratio - self.currentIndex) > 1) {
            NSInteger targetIndex = baseIndex;
            if (ratio < self.currentIndex) {
                targetIndex = baseIndex + 1;
            }
            [self scrollSelectItemAtIndex:targetIndex];
        }
        
        if (self.currentIndex == baseIndex) {
            self.scrollingTargetIndex = baseIndex + 1;
        } else {
            self.scrollingTargetIndex = baseIndex;
        }
        
        NSInteger targetIndex = -1;
        NSInteger disappearIndex = -1;
        if (baseIndex + 1 == self.currentIndex) {
            //当前选中的在右边，用户正在从右边往左边滑动
            if (ratio < (1 - self.didAppearPercent)) {
                targetIndex = baseIndex;
                disappearIndex = baseIndex + 1;
            } else {
                targetIndex = baseIndex + 1;
                disappearIndex = baseIndex;
            }
        } else {
            //当前选中的在左边，用户正在从左边往右边滑动
            if (ratio > self.didAppearPercent) {
                targetIndex = baseIndex + 1;
                disappearIndex = baseIndex;
            } else {
                targetIndex = baseIndex;
                disappearIndex = baseIndex + 1;
            }
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(mutiPageDidScroll:startIndex:endIndex:progress:)]) {
            [self.delegate mutiPageDidScroll:self startIndex:disappearIndex endIndex:targetIndex progress:remainderRatio];
        }
    }
}

- (void)scrollSelectItemAtIndex:(NSInteger)index {
    _currentIndex = index;
    _currentChildVC = self.childVCs[index];
    if (self.delegate && [self.delegate respondsToSelector:@selector(mutiPage:selectedItemAtIndex:)]) {
        [self.delegate mutiPage:self selectedItemAtIndex:index];
    }
    self.scrollingTargetIndex = -1;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.childVCs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ZZTabMutiPageCellIdentifier forIndexPath:indexPath];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *childVC = [self.childVCs vcSafeAtIndex:indexPath.row];
    if (self.parentVC && childVC) {
        if (!childVC.parentViewController) {
            childVC.view.frame = self.bounds;
            [childVC willMoveToParentViewController:self.parentVC];
            [self.parentVC addChildViewController:childVC];
            [childVC beginAppearanceTransition:YES animated:YES];
            [cell.contentView addSubview:childVC.view];
            [childVC didMoveToParentViewController:self.parentVC];
            [childVC endAppearanceTransition];
        }
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(mutiPage:willDisplayChildVC:)]) {
            [self.dataSource mutiPage:self willDisplayChildVC:childVC];
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *childVC = [self.childVCs vcSafeAtIndex:indexPath.row];
    if (childVC && childVC.parentViewController) {
        [childVC willMoveToParentViewController:nil];
        [childVC beginAppearanceTransition:NO animated:YES];
        [childVC.view removeFromSuperview];
        [childVC removeFromParentViewController];
        [childVC endAppearanceTransition];
        if (self.dataSource && [self.dataSource respondsToSelector:@selector(mutiPage:didEndDisplayingChildVC:)]) {
            [self.dataSource mutiPage:self didEndDisplayingChildVC:childVC];
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mutiPageWillBeginDragging:)]) {
        [self.delegate mutiPageWillBeginDragging:self];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(mutiPageDidEndDecelerating:)]) {
            [self.delegate mutiPageDidEndDecelerating:self];
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(mutiPageDidEndDecelerating:)]) {
        [self.delegate mutiPageDidEndDecelerating:self];
    }
}

#pragma mark - Setter

- (void)setCurrentIndex:(NSInteger)currentIndex {
    if (currentIndex < 0 || currentIndex > self.childVCs.count-1) {
        return;
    }
    _currentIndex = currentIndex;
    _currentChildVC = self.childVCs[currentIndex];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

- (void)setMutiPageScrollEnabled:(BOOL)mutiPageScrollEnabled {
    _mutiPageScrollEnabled = mutiPageScrollEnabled;
    _collectionView.scrollEnabled = mutiPageScrollEnabled;
}

#pragma mark - Getter

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = self.bounds.size;
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        UICollectionView * collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
        collectionView.backgroundColor = [UIColor whiteColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        collectionView.pagingEnabled = YES;
        collectionView.bounces = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:ZZTabMutiPageCellIdentifier];
        [self addSubview:collectionView];
        _collectionView = collectionView;
    }
    return _collectionView;
}

@end
