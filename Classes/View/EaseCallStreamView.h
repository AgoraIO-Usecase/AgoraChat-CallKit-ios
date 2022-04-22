//
//  EaseCallStreamView.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

@import UIKit;

@protocol EaseCallStreamViewDelegate;
@class EaseCallStreamViewModel;

@interface EaseCallStreamView : UICollectionViewCell

@property (nonatomic, strong) EaseCallStreamViewModel *model;
@property (readonly) UIView *displayView;
@property (nonatomic, weak) id<EaseCallStreamViewDelegate> delegate;

- (void)update;

@end

@protocol EaseCallStreamViewDelegate <NSObject>

@optional

- (void)streamViewDidTap:(EaseCallStreamView *)aVideoView;

@end
