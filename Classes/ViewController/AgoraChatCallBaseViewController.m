//
//  EaseCallBaseViewController.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallBaseViewController.h"
#import "AgoraChatCallManager+Private.h"
#import <Masonry/Masonry.h>
#import "UIImage+Ext.h"
#import "AgoraChatCallLocalizable.h"
#import "AgoraChatCallIncomingAlertView.h"

@interface AgoraChatCallBaseViewController ()

@property (nonatomic, strong) AgoraChatCallIncomingAlertView *alertView;
@property (nonatomic, strong) NSTimer *timeTimer;

@end

@implementation AgoraChatCallBaseViewController

- (instancetype)init
{
    if (self = [super init]) {
        _miniViewPosition.isLeft = NO;
        _miniViewPosition.top = 80;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setubSubViews];
    self.speakerButton.selected = YES;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(usersInfoUpdated) name:@"AgoraChatCallUserUpdated" object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self hideAlert];
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
    [self.miniButton setImage:[UIImage agoraChatCallKit_imageNamed:@"mini"] forState:UIControlStateNormal];
    [self.miniButton addTarget:self action:@selector(miniAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.miniButton];
    [self.miniButton setTintColor:UIColor.whiteColor];
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
    [self.switchCameraButton setImage:[UIImage agoraChatCallKit_imageNamed:@"switchCamera"] forState:UIControlStateNormal];
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
    [self.hangupButton setImage:[UIImage agoraChatCallKit_imageNamed:@"hangup"] forState:UIControlStateNormal];
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
    [self.answerButton setImage:[UIImage agoraChatCallKit_imageNamed:@"answer"] forState:UIControlStateNormal];
    [self.answerButton addTarget:self action:@selector(answerAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:self.answerButton];
    [self.answerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_buttonView);
        make.right.equalTo(self.contentView).offset(-40);
        make.width.height.mas_equalTo(60);
    }];
    
    self.microphoneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.microphoneButton setImage:[UIImage agoraChatCallKit_imageNamed:@"microphone_enable"] forState:UIControlStateNormal];
    [self.microphoneButton setImage:[UIImage agoraChatCallKit_imageNamed:@"microphone_disable"] forState:UIControlStateSelected];
    [self.microphoneButton addTarget:self action:@selector(muteAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:self.microphoneButton];
    [self.microphoneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView).with.multipliedBy(0.5);
        make.bottom.equalTo(_buttonView);
        make.width.height.equalTo(@(size));
    }];
    self.microphoneButton.selected = NO;
    
    _speakerButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_speakerButton setImage:[UIImage agoraChatCallKit_imageNamed:@"speaker_disable"] forState:UIControlStateNormal];
    [_speakerButton setImage:[UIImage agoraChatCallKit_imageNamed:@"speaker_enable"] forState:UIControlStateSelected];
    [_speakerButton addTarget:self action:@selector(speakerAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:_speakerButton];
    [_speakerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(_buttonView);
        make.centerX.equalTo(_contentView);
        make.width.height.equalTo(@(size));
    }];

    _enableCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_enableCameraButton setImage:[UIImage agoraChatCallKit_imageNamed:@"video_enable"] forState:UIControlStateNormal];
    [_enableCameraButton setImage:[UIImage agoraChatCallKit_imageNamed:@"video_disable"] forState:UIControlStateSelected];
    [_enableCameraButton addTarget:self action:@selector(enableVideoAction) forControlEvents:UIControlEventTouchUpInside];
    [_buttonView addSubview:_enableCameraButton];
    [_enableCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(_contentView).with.multipliedBy(1.5);
        make.bottom.equalTo(_buttonView);
        make.width.height.equalTo(@(size));
    }];
}

- (UIView*)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
    }
    return _contentView;
}

- (void)showAlert
{
    UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
    if (!_alertView) {
        __weak typeof(self)weakSelf = self;
        NSString *title = self.showAlertTitle;
        NSString *content = self.showAlertContent;
        _alertView = [[AgoraChatCallIncomingAlertView alloc] initWithTitle:title content:content tapHandle:^{
            [weakSelf hideAlert];
            [weakSelf show];
        } answerHandle:^{
            [weakSelf hideAlert];
            [keyWindow.rootViewController presentViewController:weakSelf animated:YES completion:nil];
            [weakSelf answerAction];
        } hangupHandle:^{
            [weakSelf hideAlert];
            [weakSelf miniAction];
            [weakSelf hangupAction];
        }];
    }
    
    [keyWindow addSubview:_alertView];
    _alertView.frame = CGRectMake(8, 40, keyWindow.bounds.size.width - 16, 104);
}

- (void)hideAlert
{
    [_alertView removeFromSuperview];
    _alertView = nil;
}

- (NSString *)showAlertTitle
{
    return @"";
}

- (NSString *)showAlertContent
{
    NSString *strType = AgoraChatCallLocalizableString(@"audio", nil);
    if (_callType == AgoraChatCallTypeMultiVideo) {
        strType = AgoraChatCallLocalizableString(@"conferenece", nil);
    } else if (_callType == AgoraChatCallTypeMultiAudio) {
        strType = AgoraChatCallLocalizableString(@"confereneceAudio", nil);
    } else if (_callType == AgoraChatCallType1v1Video) {
        strType = AgoraChatCallLocalizableString(@"video", nil);
    }
    return [NSString stringWithFormat:AgoraChatCallLocalizableString(@"inviteInfo", nil), strType];
}

- (void)show
{
    UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
    UIViewController *rootVC = keyWindow.rootViewController;
    if (rootVC.presentationController && rootVC.presentationController.presentedViewController) {
        [rootVC.presentationController.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }
    [rootVC presentViewController:self animated:NO completion:nil];
}

- (void)answerAction
{
    [AgoraChatCallManager.sharedManager acceptAction];
}

- (void)hangupAction
{
    if (_timeTimer) {
        [_timeTimer invalidate];
        _timeTimer = nil;
    }
    [AgoraChatCallManager.sharedManager hangupAction];
}

- (void)switchCameraAction
{
    self.switchCameraButton.selected = !self.switchCameraButton.isSelected;
    [AgoraChatCallManager.sharedManager switchCameraAction];
}

- (void)speakerAction
{
    BOOL speakeOut = !self.speakerButton.isSelected;
    [AgoraChatCallManager.sharedManager speakeOut:speakeOut];
    [self didSpeakeOut:speakeOut];
}

- (void)muteAction
{
    [AgoraChatCallManager.sharedManager muteAudio:!self.microphoneButton.selected];
}

- (void)enableVideoAction
{
    self.enableCameraButton.selected = !self.enableCameraButton.isSelected;
    int state = [AgoraChatCallManager.sharedManager muteLocalVideoStream:self.enableCameraButton.selected];
    NSLog(@"%d", state);
}

- (void)miniAction
{
    
}

- (void)callFinish
{
    if (_timeTimer) {
        [_timeTimer invalidate];
        _timeTimer = nil;
    }
}

#pragma mark - timer
- (void)startTimer
{
    if (!_timeTimer) {
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
    
}

- (void)setupLocalVideo
{
    
}

- (void)setupRemoteVideoView:(NSUInteger)uid size:(CGSize)size
{
    
}

- (void)didMuteAudio:(BOOL)mute
{
    self.microphoneButton.selected = mute;
}

- (void)didSpeakeOut:(BOOL)speakeOut
{
    self.speakerButton.selected = speakeOut;
}

@end
