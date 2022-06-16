//
//  EaseCallStreamView.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

@import UIKit;

@protocol AgoraChatCallStreamViewDelegate;
@class AgoraChatCallStreamViewModel;

@interface AgoraChatCallStreamView : UICollectionViewCell

@property (nonatomic, strong) AgoraChatCallStreamViewModel *model;
@property (readonly) UIView *displayView;
@property (nonatomic, weak) id<AgoraChatCallStreamViewDelegate> delegate;
@property (nonatomic, assign) BOOL panGestureActionEnable;

- (void)update;
- (void)updateShowingImageAndUsername;
- (void)updateStatusViews;

@end

@protocol AgoraChatCallStreamViewDelegate <NSObject>

@optional

- (void)streamViewDidTap:(AgoraChatCallStreamView *)aVideoView;
- (void)streamView:(AgoraChatCallStreamView *)aVideoView didPan:(UIPanGestureRecognizer *)panGesture;

@end
