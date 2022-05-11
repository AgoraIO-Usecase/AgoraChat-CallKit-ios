//
//  EaseCallStreamView.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallStreamView.h"
#import <Masonry/Masonry.h>
#import "UIImage+Ext.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AgoraChatCallStreamViewModel.h"
#import "AgoraChatCallManager.h"

@interface AgoraChatCallStreamView()

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIVisualEffectView *effectView;
@property (nonatomic, strong) UIView *speakingView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *statelabel;
@property (nonatomic, strong) UIImageView *voiceStatusView;
@property (nonatomic, strong) UIImageView *videoStatusView;

@property (nonatomic, strong) UIPanGestureRecognizer *panGes;

@end

@implementation AgoraChatCallStreamView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentView.layer.masksToBounds = YES;
        
        _bgImageView = [[UIImageView alloc] init];
        _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_bgImageView];
        [_bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
        
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.layer.masksToBounds = YES;
        [self.contentView addSubview:_effectView];
        [_effectView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(@0);
        }];
        
        _displayView = [[UIView alloc] init];
        _displayView.backgroundColor = UIColor.clearColor;
        _displayView.layer.masksToBounds = YES;
        [self.contentView addSubview:_displayView];
        [_displayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        
        _speakingView = [[UIView alloc] init];
        _speakingView.hidden = YES;
        _speakingView.layer.cornerRadius = 44;
        _speakingView.backgroundColor = [UIColor colorWithRed:0.078 green:1 blue:0.447 alpha:1];
        [self.contentView addSubview:_speakingView];
        
        _avatarImageView = [[UIImageView alloc] init];
        _avatarImageView.contentMode = UIViewContentModeScaleAspectFit;
        _avatarImageView.layer.masksToBounds = YES;
        [self.contentView addSubview:_avatarImageView];
        [_speakingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(_avatarImageView);
            make.width.height.equalTo(@88);
        }];
        
        _voiceStatusView = [[UIImageView alloc] init];
        _voiceStatusView.hidden = YES;
        [self.contentView addSubview:_voiceStatusView];
        
        _videoStatusView = [[UIImageView alloc] init];
        _videoStatusView.hidden = YES;
        _videoStatusView.image = [UIImage agoraChatCallKit_imageNamed:@"video_close"];
        [self.contentView addSubview:_videoStatusView];
        
        _nameLabel = [[UILabel alloc] init];
        _nameLabel.textColor = UIColor.whiteColor;
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_nameLabel];
        
        _statelabel = [[UILabel alloc] init];
        _statelabel.textColor = UIColor.whiteColor;
        _statelabel.font = [UIFont systemFontOfSize:16];
        _statelabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_statelabel];
        [_statelabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(_nameLabel);
            make.top.equalTo(_nameLabel.mas_bottom).offset(4);
        }];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
        [self addGestureRecognizer:tap];
        
        _panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanAction:)];
        _panGes.enabled = NO;
        [self addGestureRecognizer:_panGes];
    }
    
    return self;
}

- (void)setModel:(AgoraChatCallStreamViewModel *)model
{
    _model = model;
    [self update];
}

- (void)setPanGestureActionEnable:(BOOL)panGestureActionEnable
{
    _panGes.enabled = panGestureActionEnable;
}

- (BOOL)panGestureActionEnable
{
    return _panGes.isEnabled;
}

- (void)update
{
    if (!_model.enableVoice) {
        _model.isTalking = NO;
    }
    
    [self updateBG];
    [self updateShowingImageAndUsername];
    [self updateStatusViews];
    
    NSString *defaultImageName = (_model.callType == AgoraChatCallType1v1Audio || _model.callType == AgoraChatCallType1v1Video) ? @"user_avatar_default" : @"group_avatar_default";
    if (!_avatarImageView.hidden) {
        if (_model.showUserHeaderImage) {
            _avatarImageView.image = _model.showUserHeaderImage;
            _bgImageView.image = _model.showUserHeaderImage;
        } else {
            [_avatarImageView sd_setImageWithURL:_model.showUserHeaderURL placeholderImage:[UIImage agoraChatCallKit_imageNamed:defaultImageName]];
            [_bgImageView sd_setImageWithURL:_model.showUserHeaderURL placeholderImage:[UIImage agoraChatCallKit_imageNamed:defaultImageName]];
        }
    }
    
    if (_model.callType != AgoraChatCallTypeMultiAudio) {
        return;
    }
    
    _speakingView.hidden = !_model.isTalking;
}

- (void)updateBG
{
    _displayView.hidden = !_model.enableVideo;
    if (_model.isMini) {
        self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
        self.contentView.layer.cornerRadius = 12;
        _effectView.layer.cornerRadius = 12;
        _displayView.layer.cornerRadius = 12;
    } else {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.contentView.layer.cornerRadius = 0;
        _effectView.layer.cornerRadius = 0;
        _displayView.layer.cornerRadius = 0;
    }
    _bgImageView.hidden = _avatarImageView.hidden || _model.isMini || _model.enableVideo || _model.callType == AgoraChatCallTypeMultiAudio;
    _effectView.hidden = _bgImageView.hidden;
}

- (void)updateShowingImageAndUsername
{
    _nameLabel.text = _model.showUsername;
    _nameLabel.font = [UIFont systemFontOfSize:14];
    
    if (_model.isMini) {
        _statelabel.hidden = YES;
        _avatarImageView.hidden = _model.enableVideo;
        _nameLabel.hidden = _model.enableVideo;
        _avatarImageView.layer.cornerRadius = 18;
        [_avatarImageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@36);
            make.centerY.equalTo(self).offset(-13);
            make.centerX.equalTo(self.contentView);
        }];
        [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(@-8);
            make.centerX.equalTo(self);
        }];
        return;
    }
    
    if (_model.callType == AgoraChatCallType1v1Audio || _model.callType == AgoraChatCallType1v1Video) {
        if (_model.enableVideo && _model.joined) {
            _avatarImageView.hidden = YES;
            _nameLabel.hidden = YES;
            _statelabel.hidden = YES;
        } else {
            _avatarImageView.hidden = NO;
            _nameLabel.hidden = NO;
            _statelabel.hidden = NO;
            _nameLabel.font = [UIFont systemFontOfSize:24];
            _avatarImageView.layer.cornerRadius = 50;
            [_avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@100);
                make.centerY.equalTo(self).offset(-219);
                make.centerX.equalTo(self.contentView);
            }];
            [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_avatarImageView.mas_bottom).offset(7);
                make.centerX.equalTo(self.contentView);
            }];
        }
    } else if (_model.callType == AgoraChatCallTypeMultiVideo) {
        _statelabel.hidden = _model.joined;
        _avatarImageView.hidden = _model.enableVideo;
        _nameLabel.hidden = _avatarImageView.hidden;
        _avatarImageView.layer.cornerRadius = 50;
        if (_model.joined) {
            [_avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@100);
                make.centerY.equalTo(self).offset(-42);
                make.centerX.equalTo(self.contentView);
            }];
            [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(@-8);
                make.left.equalTo(@11);
            }];
        } else {
            [_avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.width.height.equalTo(@100);
                make.centerY.equalTo(self).offset(-219);
                make.centerX.equalTo(self.contentView);
            }];
            [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(_avatarImageView.mas_bottom).offset(7);
                make.centerX.equalTo(self.contentView);
            }];
        }
    } else {
        _statelabel.hidden = YES;
        _avatarImageView.hidden = NO;
        _nameLabel.hidden = NO;
        _avatarImageView.layer.cornerRadius = 40;
        [_avatarImageView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@80);
            make.centerY.equalTo(self).offset(-42);
            make.centerX.equalTo(self.contentView);
        }];
        [_nameLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_avatarImageView.mas_bottom).offset(12);
            make.centerX.equalTo(_avatarImageView);
        }];
    }
    
    if (!_statelabel.hidden) {
        _statelabel.text = _model.showStatusText;
    }
}

- (void)updateStatusViews
{
    if (_model.callType == AgoraChatCallType1v1Audio) {
        _voiceStatusView.hidden = YES;
        _videoStatusView.hidden = YES;
    } else if (_model.callType == AgoraChatCallType1v1Video) {
        _voiceStatusView.hidden = _model.enableVoice || !_model.isMini;
        _videoStatusView.hidden = _model.enableVideo || !_model.isMini;
    } else if (_model.callType == AgoraChatCallTypeMultiVideo) {
        _voiceStatusView.hidden = _model.enableVoice || _model.isMini;
        _videoStatusView.hidden = _model.enableVideo || !_model.joined || _model.isMini;
    } else if (_model.callType == AgoraChatCallTypeMultiAudio) {
        _voiceStatusView.hidden = _model.enableVoice || _model.isMini;
        _videoStatusView.hidden = YES;
    }
    
    if (_model.callType == AgoraChatCallTypeMultiVideo || _model.callType == AgoraChatCallType1v1Video) {
        _voiceStatusView.image = [UIImage agoraChatCallKit_imageNamed:@"microphone_close"];
        CGFloat right = 5;
        if (!_voiceStatusView.hidden) {
            [_voiceStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(@(-right));
                make.width.height.equalTo(@20);
                make.bottom.equalTo(@(-7));
            }];
            right += 27;
        }
        if (!_videoStatusView.hidden) {
            [_videoStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(@(-right));
                make.width.height.equalTo(@20);
                make.bottom.equalTo(@(-7));
            }];
        }
    } else if (_model.callType == AgoraChatCallTypeMultiAudio) {
        _voiceStatusView.image = [UIImage agoraChatCallKit_imageNamed:@"audio_call_microphone_close"];
        [_voiceStatusView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.height.equalTo(@20);
            make.right.bottom.equalTo(_avatarImageView);
        }];
    }
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

- (void)handlePanAction:(UIPanGestureRecognizer *)pan
{
    if (_delegate && [_delegate respondsToSelector:@selector(streamView:didPan:)]) {
        [_delegate streamView:self didPan:pan];
    }
}

@end
