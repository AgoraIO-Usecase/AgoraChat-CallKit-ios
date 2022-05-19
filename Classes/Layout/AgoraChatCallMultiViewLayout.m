//
//  EaseCallMultiViewLayout.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/24.
//

#import "AgoraChatCallMultiViewLayout.h"

@interface AgoraChatCallMultiViewLayout ()

@property (nonatomic, strong) NSMutableDictionary *layoutDictionary;
@property (nonatomic, assign) NSInteger allCount;
@property (nonatomic, assign) CGSize collectionViewSize;
@property (nonatomic, assign) CGPoint voiceOffset;

@end

@implementation AgoraChatCallMultiViewLayout

- (instancetype)init
{
    if (self = [super init]) {
        _bigIndex = -1;
    }
    return self;
}

- (void)prepareLayout
{
    [super prepareLayout];
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _allCount = [self.collectionView numberOfItemsInSection:0];
    _collectionViewSize = self.collectionView.bounds.size;
    if (_layoutDictionary) {
        [_layoutDictionary removeAllObjects];
    } else {
        _layoutDictionary = [NSMutableDictionary dictionary];
    }

    if (_isVideo || _allCount > 6) {
        _voiceOffset = CGPointZero;
    } else {
        CGFloat x = 0;
        CGFloat y = 0;
        if (_allCount < 3) {
            x = _collectionViewSize.width * (3 - _allCount) / 6;
        }
        if ((_allCount - 1) / 3 <= 2) {
            y = 40;
        }
        _voiceOffset = CGPointMake(floor(x), y);
    }
}

- (NSArray<__kindof UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSMutableArray *result = [NSMutableArray array];
    if (_bigIndex != -1) {
        UICollectionViewLayoutAttributes *layout = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:_bigIndex inSection:0]];
        [result addObject:layout];
    } else {
        CGFloat x = floor(rect.origin.x);
        NSInteger page = (x / _collectionViewSize.width);
        NSInteger showBeginIndex = page * (_isVideo ? 4 : 9);
        NSInteger showCount = _allCount - showBeginIndex;
        if (showCount > (_isVideo ? 4 : 9)) {
            showCount = (_isVideo ? 4 : 9);
        }
        for (int i = 0; i < showCount; i ++) {
            UICollectionViewLayoutAttributes *layout = [self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:showBeginIndex + i inSection:0]];
            [result addObject:layout];
        }
    }
    return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layout = _layoutDictionary[indexPath];
    if (layout) {
        return layout;
    }
    
    layout = [super layoutAttributesForItemAtIndexPath:indexPath];
    _layoutDictionary[indexPath] = layout;
    if (_isVideo) {
        if (_bigIndex != -1) {
            layout.frame = CGRectMake(0, 0, _collectionViewSize.width, _collectionViewSize.height);
        } else if (_allCount == 1) {
            if (indexPath.item == 0) {
                layout.frame = CGRectMake(0, 0, _collectionViewSize.width, _collectionViewSize.height);
            }
            layout.zIndex = 0;
        } else if (_allCount == 2) {
            if (indexPath.item == 0) {
                BOOL videoEnable = YES;
                if (_getVideoEnableBlock) {
                    videoEnable = _getVideoEnableBlock(indexPath);
                }
                if (videoEnable) {
                    layout.frame = CGRectMake(_collectionViewSize.width - 100, 80, 80, 100);
                } else {
                    layout.frame = CGRectMake(_collectionViewSize.width - 96, 80, 76, 76);
                }
                layout.zIndex = 1;
            } else if (indexPath.item == 1) {
                layout.frame = CGRectMake(0, 0, _collectionViewSize.width, _collectionViewSize.height);
                layout.zIndex = 0;
            }
        } else if (_allCount == 3 && indexPath.item == 2) {
            layout.frame = CGRectMake(0, floor(_collectionViewSize.height / 2), floor(_collectionViewSize.width / 2), floor(_collectionViewSize.height / 2));
            layout.zIndex = 0;
        } else {
            layout.frame = [self videoFrame:indexPath];
            layout.zIndex = 0;
        }
    } else {
        layout.frame = [self audioFrame:indexPath];
        layout.zIndex = 0;
    }
    return layout;
}

- (CGRect)videoFrame:(NSIndexPath *)indexPath
{
    NSInteger item = indexPath.item;
    CGFloat x = (item + 1) / 4 * _collectionViewSize.width + item % 2 * _collectionViewSize.width / 2;
    CGFloat y = item % 4 / 2 * _collectionViewSize.height / 2;
    return CGRectMake(floor(x), floor(y), floor(_collectionViewSize.width / 2), floor(_collectionViewSize.height / 2));
}

- (CGRect)audioFrame:(NSIndexPath *)indexPath
{
    NSInteger item = indexPath.item;
    CGFloat x = (item + 1) / 9 * _collectionViewSize.width + item % 3 * _collectionViewSize.width / 3 + _voiceOffset.x;
    CGFloat y = item % 9 / 3 * _collectionViewSize.height / 3 + _voiceOffset.y;
    return CGRectMake(floor(x), floor(y), floor(_collectionViewSize.width / 3), floor(_collectionViewSize.height / 3));
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

//- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
//{
//    return velocity;
//}

- (CGSize)collectionViewContentSize
{
    NSInteger pageSize = _isVideo ? 4 : 9;
    NSInteger count = (_allCount + pageSize - 1) / pageSize;
    CGSize size = self.collectionView.bounds.size;
    return CGSizeMake(size.width * count, size.height);
}

@end
