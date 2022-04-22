//
//  EaseCallBaseViewController.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "EaseCallBaseViewController.h"
#import "EaseCallManager+Private.h"
#import <Masonry/Masonry.h>
#import "UIImage+Ext.h"
#import "EaseCallLocalizable.h"

@interface EaseCallBaseViewController ()

@end

@implementation EaseCallBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setubSubViews];
    
    self.speakerButton.selected = YES;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(usersInfoUpdated) name:@"EaseCallUserUpdated" object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)usersInfoUpdated
{
    
}

- (void)setubSubViews
{
    int size = 60;
    
    UIView *bgView = [[UIView alloc] init];
    bgView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:bgView];
    [bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    _bgImageView = [[UIImageView alloc] init];
    _bgImageView.contentMode = UIViewContentModeScaleAspectFill;
    [bgView addSubview:_bgImageView];
    [_bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(bgView);
    }];
    
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [_bgImageView addSubview:visualEffectView];
    [visualEffectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_bgImageView);
    }];
    
    [self.view addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    self.miniButton = [[UIButton alloc] init];
    self.miniButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.miniButton setImage:[UIImage imageNamedFromBundle:@"mini"] forState:UIControlStateNormal];
    [self.miniButton addTarget:self action:@selector(miniAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.miniButton];
    [self.miniButton setTintColor:[UIColor whiteColor]];
    [self.miniButton mas_makeConstraints:^(MASConstraintMaker *make) {
        if (@available(iOS 11,*)) {
            make.top.equalTo(self.contentView.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.equalTo(self.contentView);
        }
        make.left.equalTo(@10);
        make.width.height.equalTo(@40);
    }];
    
    self.switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.switchCameraButton setImage:[UIImage imageNamedFromBundle:@"switchCamera"] forState:UIControlStateNormal];
    [self.switchCameraButton addTarget:self action:@selector(switchCameraAction) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:self.switchCameraButton];
    [self.switchCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_miniButton);
        make.width.height.equalTo(@40);
        make.right.equalTo(@-18);
    }];
    
    _buttonView = [[UIView alloc] init];
    _buttonView.backgroundColor = UIColor.clearColor;
    [_contentView addSubview:_buttonView];
    [_buttonView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_contentView);
        if (@available(iOS 11,*)) {
            make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(-60);
        } else {
            make.bottom.equalTo(self.contentView).offset(-60);
        }
        make.height.mas_equalTo(100);
    }];
    
    self.hangupButton = [[UIButton alloc] init];
    self.hangupButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.hangupButton setImage:[UIImage imageNamedFromBundle:@"hangup"] forState:UIControlStateNormal];
    [self.hangupButton addTarget:self action:@selector(hangupAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:self.hangupButton];
    [self.hangupButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_buttonView);
        make.left.equalTo(@30);
        make.width.height.equalTo(@60);
        //make.centerX.equalTo(@60);
    }];
    
    self.answerButton = [[UIButton alloc] init];
    self.answerButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.answerButton setImage:[UIImage imageNamedFromBundle:@"answer"] forState:UIControlStateNormal];
    [self.answerButton addTarget:self action:@selector(answerAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:self.answerButton];
    [self.answerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_buttonView);
        make.right.equalTo(self.contentView).offset(-40);
        make.width.height.mas_equalTo(60);
    }];
    
    self.microphoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.microphoneButton setImage:[UIImage imageNamedFromBundle:@"microphone_disable"] forState:UIControlStateNormal];
    [self.microphoneButton setImage:[UIImage imageNamedFromBundle:@"microphone_enable"] forState:UIControlStateSelected];
    [self.microphoneButton addTarget:self action:@selector(muteAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:self.microphoneButton];
    [self.microphoneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView).with.multipliedBy(0.5);
        make.bottom.equalTo(_buttonView);
        make.width.height.equalTo(@(size));
    }];
    self.microphoneButton.selected = NO;
    
    _speakerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_speakerButton setImage:[UIImage imageNamedFromBundle:@"speaker_disable"] forState:UIControlStateNormal];
    [_speakerButton setImage:[UIImage imageNamedFromBundle:@"speaker_enable"] forState:UIControlStateSelected];
    [_speakerButton addTarget:self action:@selector(speakerAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:_speakerButton];
    [_speakerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_buttonView);
        make.centerX.equalTo(_contentView);
        make.width.height.equalTo(@(size));
    }];

    _enableCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_enableCameraButton setImage:[UIImage imageNamedFromBundle:@"video_disable"] forState:UIControlStateNormal];
    [_enableCameraButton setImage:[UIImage imageNamedFromBundle:@"video_enable"] forState:UIControlStateSelected];
    [_enableCameraButton addTarget:self action:@selector(enableVideoAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:_enableCameraButton];
    [_enableCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_contentView).with.multipliedBy(1.5);
        make.bottom.equalTo(_buttonView);
        make.width.height.equalTo(@(size));
    }];
    _timeLabel = nil;
}

- (UIView*)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (void)answerAction
{
    [EaseCallManager.sharedManager acceptAction];
}

- (void)hangupAction
{
    if (_timeTimer) {
        [_timeTimer invalidate];
        _timeTimer = nil;
    }
    [EaseCallManager.sharedManager hangupAction];
}

- (void)switchCameraAction
{
    self.switchCameraButton.selected = !self.switchCameraButton.isSelected;
    [EaseCallManager.sharedManager switchCameraAction];
}

- (void)speakerAction
{
    self.speakerButton.selected = !self.speakerButton.isSelected;
    [EaseCallManager.sharedManager speakeOut:self.speakerButton.selected];
}

- (void)muteAction
{
    self.microphoneButton.selected = !self.microphoneButton.isSelected;
    [EaseCallManager.sharedManager muteAudio:self.microphoneButton.selected];
}

- (void)enableVideoAction
{
    self.enableCameraButton.selected = !self.enableCameraButton.isSelected;
    [EaseCallManager.sharedManager enableVideo:self.enableCameraButton.selected];
}

- (void)miniAction
{
}

- (void)callFinish
{
    
}

#pragma mark - timer
- (void)startTimer
{
    if (!_timeLabel) {
        self.timeLabel = [[UILabel alloc] init];
        self.timeLabel.backgroundColor = UIColor.clearColor;
        self.timeLabel.font = [UIFont systemFontOfSize:25];
        self.timeLabel.textColor = UIColor.whiteColor;
        self.timeLabel.textAlignment = NSTextAlignmentRight;
        self.timeLabel.text = @"00:00";
        [self.contentView addSubview:self.timeLabel];
        
        [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.hangupButton.mas_top).with.offset(-20);
            make.centerX.equalTo(self.contentView);
        }];
        _timeTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timeTimerAction:) userInfo:nil repeats:YES];
    }
}

- (void)timeTimerAction:(id)sender
{
    _timeLength += 1;
    int m = (_timeLength) / 60;
    int s = _timeLength - m * 60;
    
    [self callTimerDidChange:m sec:s];
    
}

- (void)callTimerDidChange:(NSUInteger)min sec:(NSUInteger)sec
{
    self.timeLabel.text = [NSString stringWithFormat:@"%02d:%02d", min, sec];
}

@end
