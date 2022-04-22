//
//  EaseCallStreamView.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "EaseCallStreamView.h"
#import <Masonry/Masonry.h>
#import "UIImage+Ext.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "EaseCallStreamViewModel.h"

@interface EaseCallStreamView()

@property (nonatomic, strong) UIView *speakingView;
@property (nonatomic, strong) UIImageView *bgView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *voiceStatusView;
@property (nonatomic, strong) UIImageView *videoStatusView;
@property (nonatomic) NSTimer *timeTimer;

@end

@implementation EaseCallStreamView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.blackColor;
        self.layer.masksToBounds = YES;
        
        _speakingView = [[UIView alloc] init];
        _speakingView.hidden = YES;
        _speakingView.layer.cornerRadius = 44;
        _speakingView.backgroundColor = [UIColor colorWithRed:0.078 green:1 blue:0.447 alpha:1];
        [self.contentView addSubview:_speakingView];
        
        _bgView = [[UIImageView alloc] init];
        _bgView.contentMode = UIViewContentModeScaleAspectFit;
        _bgView.userInteractionEnabled = YES;
        _bgView.image = [UIImage imageNamedFromBundle:@"icon"];
        [self.contentView addSubview:_bgView];
        [_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).offset(-42);
            make.width.equalTo(@100);
            make.height.equalTo(@100);
        }];
        
        [_speakingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_bgView);
            make.width.height.equalTo(@88);
        }];
        
        _displayView = [[UIView alloc] init];
        _displayView.backgroundColor = UIColor.redColor;
        [self.contentView addSubview:_displayView];
        [_displayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        _voiceStatusView = [[UIImageView alloc] init];
        _voiceStatusView.hidden = YES;
        _voiceStatusView.image = [UIImage imageNamedFromBundle:@"microphonenclose"];
        [self.contentView addSubview:_voiceStatusView];
        [_voiceStatusView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@(-7));
            make.right.equalTo(@-5);
            make.width.height.equalTo(@20);
        }];
        
        _videoStatusView = [[UIImageView alloc] init];
        _videoStatusView.hidden = YES;
        [self.contentView addSubview:_videoStatusView];
        [_videoStatusView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@(-7));
            make.right.equalTo(@-32);
            make.width.height.equalTo(@20);
        }];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColor.whiteColor;
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_nameLabel];
        [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@-8);
            make.left.equalTo(@11);
        }];
        [self bringSubviewToFront:_nameLabel];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)setModel:(EaseCallStreamViewModel *)model
{
    _model = model;
    [self update];
}

- (void)update
{
    if (!_model.enableVoice) {
        _model.isTalking = NO;
    }
    
    _bgView.hidden = _model.enableVideo;
    _displayView.hidden = !_model.enableVideo;
    _voiceStatusView.hidden = _model.enableVoice;
    _videoStatusView.hidden = _model.enableVideo;
    
    _nameLabel.text = _model.showUsername;
    if (!_bgView.hidden) {
        if (_model.showUserHeaderImage) {
            _bgView.image = _model.showUserHeaderImage;
        } else if (_model.showUserHeaderURL) {
            [_bgView sd_setImageWithURL:_model.showUserHeaderURL];
        } else {
            _bgView.image = nil;
        }
    }
    
    if (_model.isMini) {
        [_bgView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@36);
            make.centerY.equalTo(self).offset(-13);
            make.centerX.equalTo(self.contentView);
        }];
        self.backgroundColor = [UIColor colorWithWhite:0.7 alpha:1];
        self.layer.cornerRadius = 12;
        [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@-8);
            make.centerX.equalTo(self);
        }];
    } else {
        if (_model.callType == EaseCallTypeMulti) {
            [_bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@100);
                make.centerY.equalTo(self).offset(-42);
                make.centerX.equalTo(self.contentView);
            }];
            [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(@-8);
                make.left.equalTo(@11);
            }];
            CGFloat right = 5;
            if (!_voiceStatusView.hidden) {
                [_voiceStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(@(-right));
                    make.width.height.equalTo(@20);
                }];
                right += 27;
            }
            if (!_videoStatusView.hidden) {
                [_videoStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(@(-right));
                    make.width.height.equalTo(@20);
                }];
            }
        } else {
            [_bgView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@80);
                make.centerY.equalTo(self).offset(-42);
                make.centerX.equalTo(self.contentView);
            }];
            [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_bgView.mas_bottom).offset(12);
                make.centerX.equalTo(_bgView);
            }];
            [_voiceStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@20);
                make.right.bottom.equalTo(_bgView);
            }];
        }
        self.backgroundColor = UIColor.blackColor;
        self.layer.cornerRadius = 0;
    }
    
    if (_model.callType != EaseCallTypeMultiAudio) {
        return;
    }
    
    _speakingView.hidden = !_model.isTalking;
}

- (void)timeTalkingAction:(id)sender
{
    _voiceStatusView.hidden = YES;
    _model.isTalking = NO;
    _speakingView.hidden = !_model.isTalking;
}

#pragma mark - UITapGestureRecognizer

- (void)handleTapAction:(UITapGestureRecognizer *)aTap
{
    if (aTap.state == UIGestureRecognizerStateEnded) {
        if (_delegate && [_delegate respondsToSelector:@selector(streamViewDidTap:)]) {
            [_delegate streamViewDidTap:self];
        }
    }
}

@end
