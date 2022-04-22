//
//  EaseCallSingleViewController.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "EaseCallSingleViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Ext.h"
#import "EaseCallLocalizable.h"
#import "EaseCallStreamViewModel.h"
#import "EaseCallManager.h"

@import AgoraChat;

@interface EaseCallSingleViewController ()<EaseCallStreamViewDelegate>

@property (nonatomic) NSString* remoteUid;
@property (nonatomic) UILabel* statusLable;
@property (nonatomic) EaseCallType type;
@property (nonatomic) UILabel * tipLabel;
@property (nonatomic,strong) UILabel* remoteNameLable;
@property (nonatomic,strong) UIImageView* remoteHeadView;

@end

@implementation EaseCallSingleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isConnected = NO;
    self.isMini = NO;
    
    self.localView = [[EaseCallStreamView alloc] init];
    EaseCallStreamViewModel *localModel = [[EaseCallStreamViewModel alloc] init];
    localModel.enableVideo = self.callType == EaseCallType1v1Video;
    localModel.callType = self.callType;
    _localView.model = localModel;
    [self setLocalDisplayViewEnableVideo:YES];
    
    self.remoteView = [[EaseCallStreamView alloc] init];
    EaseCallStreamViewModel *remoteModel = [[EaseCallStreamViewModel alloc] init];
    remoteModel.enableVideo = self.callType == EaseCallType1v1Video;
    remoteModel.callType = self.callType;
    _remoteView.model = remoteModel;
    [self setRemoteDisplayViewEnableVideo:YES];
    
    if (self.callType == EaseCallType1v1Video) {
        [EaseCallManager.sharedManager setupLocalVideo:_localView.displayView];
    }
    
    NSURL *selfUrl = [EaseCallManager.sharedManager getHeadImageByUserName:AgoraChatClient.sharedClient.currentUsername];
    [self.bgImageView sd_setImageWithURL:selfUrl];
    
    NSURL *remoteUrl = [EaseCallManager.sharedManager getHeadImageByUserName:self.remoteUid];
    self.remoteHeadView = [[UIImageView alloc] init];
    [self.contentView addSubview:self.remoteHeadView];
    [self.remoteHeadView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@100);
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(@65);
    }];
    [self.remoteHeadView sd_setImageWithURL:remoteUrl];
    
    _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 325, 330, 30)];
    _tipLabel.backgroundColor = [UIColor blackColor];
    _tipLabel.layer.cornerRadius = 5;
    _tipLabel.layer.masksToBounds = YES;
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    _tipLabel.textColor = [UIColor whiteColor];
    _tipLabel.alpha = 0.0;
    [self.contentView addSubview:_tipLabel];
    
    self.remoteNameLable = [[UILabel alloc] init];
    self.remoteNameLable.backgroundColor = [UIColor clearColor];
    self.remoteNameLable.font = [UIFont systemFontOfSize:24];
    self.remoteNameLable.textColor = [UIColor whiteColor];
    self.remoteNameLable.textAlignment = NSTextAlignmentCenter;
    self.remoteNameLable.text = [EaseCallManager.sharedManager getNicknameByUserName:self.remoteUid];
    [self.contentView addSubview:self.remoteNameLable];
    [self.remoteNameLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.remoteHeadView.mas_bottom).offset(7);
        make.centerX.equalTo(self.contentView);
    }];
    self.statusLable = [[UILabel alloc] init];
    self.statusLable.backgroundColor = [UIColor clearColor];
    self.statusLable.font = [UIFont systemFontOfSize:16];
    self.statusLable.textColor = [UIColor whiteColor];
    self.statusLable.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.statusLable];
    [self.statusLable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.remoteNameLable.mas_bottom).with.offset(4);
        make.centerX.equalTo(self.contentView);
    }];
    
    self.switchToVoice = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.switchToVoice setTintColor:[UIColor whiteColor]];
    [self.switchToVoice setImage:[UIImage imageNamedFromBundle:@"Audio-mute"] forState:UIControlStateNormal];
    [self.switchToVoice addTarget:self action:@selector(switchToVoiceAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.switchToVoice];
    [self.switchToVoice mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@40);
        make.bottom.equalTo(self.buttonView);
        make.width.height.equalTo(@60);
    }];
    
    if (self.isCaller) {
        self.statusLable.text = EaseCallLocalizableString(@"waitforanswer",nil);
        self.answerButton.hidden = YES;
    } else {
        self.statusLable.text = EaseCallLocalizableString(@"receiveCallInviteprompt",nil);
        self.localView.hidden = YES;
        self.remoteView.hidden = YES;
    }
    [self updatePos];
}

- (void)switchToVoiceAction
{
    [EaseCallManager.sharedManager switchToVoice];
    if (!_isConnected && !_isCaller) {
        [self answerAction];
    } else {
        [EaseCallManager.sharedManager sendVideoToVoiceMsg];
    }
}

- (void)updateToVoice
{
    if (self.type == EaseCallType1v1Audio) {
        return;
    }
    if (self.isMini) {
        self.remoteView.model.enableVideo = NO;
        [self.remoteView update];
    }
    self.type = EaseCallType1v1Audio;
    [self updatePos];
}

- (instancetype)initWithisCaller:(BOOL)aIsCaller type:(EaseCallType)aType remoteName:(NSString*)aRemoteName
{
    if (self = [super init]) {
        self.isCaller = aIsCaller;
        self.remoteUid = aRemoteName;
        self.type = aType;
    }
    return self;
}

- (void)updatePos
{
    if (self.type == EaseCallType1v1Audio) {
        // 音频
        self.switchToVoice.hidden = YES;
        self.enableCameraButton.hidden = YES;
        self.switchCameraButton.hidden = YES;
        self.localView.hidden = YES;
        self.remoteView.hidden = YES;
        self.remoteNameLable.hidden = NO;
        [self.remoteNameLable mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.remoteHeadView.mas_bottom).with.offset(30);
            make.centerX.equalTo(self.contentView);
        }];
        if (_isConnected) {
            // 接通
            NSURL *remoteUrl = [EaseCallManager.sharedManager getHeadImageByUserName:self.remoteUid];
            [self.bgImageView sd_setImageWithURL:remoteUrl];
            
            self.microphoneButton.hidden = NO;
            self.speakerButton.hidden = NO;
            self.answerButton.hidden = YES;
            self.remoteHeadView.hidden = NO;
            self.statusLable.hidden = YES;
            
            [self.speakerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.buttonView);
                make.width.height.equalTo(@60);
                make.left.equalTo(@40);
            }];
            [self.microphoneButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.buttonView);
                make.width.height.equalTo(@60);
                make.centerX.equalTo(self.contentView);
            }];
            [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(@-40);
                make.width.height.equalTo(@60);
                make.bottom.equalTo(self.buttonView);
            }];
        } else {
            self.statusLable.hidden = NO;
            // 未接通
            if (_isCaller) {
                // 发起方
                self.microphoneButton.hidden = NO;
                self.speakerButton.hidden = NO;
                self.answerButton.hidden = YES;
                
                [self.speakerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.bottom.equalTo(self.buttonView);
                    make.width.height.equalTo(@60);
                    make.left.equalTo(@40);
                }];
                [self.microphoneButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.centerX.equalTo(self.contentView);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                    
                }];
                [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(@-40);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
            } else {
                self.microphoneButton.hidden = YES;
                self.speakerButton.hidden = YES;
                self.answerButton.hidden = NO;
                [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(@40);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
                [self.answerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(@-40);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
            }
        }
    } else {
        //视频
        self.enableCameraButton.hidden = YES;
        self.microphoneButton.hidden = NO;
        self.speakerButton.hidden = YES;
        self.switchCameraButton.hidden = NO;
        self.localView.hidden = NO;
        [self.remoteNameLable mas_updateConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.remoteHeadView.mas_bottom).offset(40);
        }];
        if (_isConnected) {
            // 接通
            self.remoteView.hidden = NO;
            self.remoteHeadView.hidden = YES;
            self.remoteNameLable.hidden = YES;
            self.answerButton.hidden = YES;
            self.statusLable.hidden = YES;
            self.switchToVoice.hidden = NO;
            
            [self.switchToVoice mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(@40);
                make.bottom.equalTo(self.buttonView);
                make.width.height.equalTo(@60);
            }];
            [self.microphoneButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.equalTo(self.buttonView);
                make.centerX.equalTo(self.contentView);
                make.width.height.equalTo(@60);
            }];
            [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(@-40);
                make.width.height.equalTo(@60);
                make.bottom.equalTo(self.buttonView);
            }];
        } else {
            // 未接通
            self.remoteView.hidden = YES;
            self.statusLable.hidden = NO;
            if (_isCaller) {
                // 发起方
                self.answerButton.hidden = YES;
                self.switchToVoice.hidden = NO;
                [self.switchToVoice mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(@40);
                    make.bottom.equalTo(self.buttonView);
                    make.width.height.equalTo(@60);
                }];
                [self.microphoneButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.bottom.equalTo(self.buttonView);
                    make.centerX.equalTo(self.contentView);
                    make.width.height.equalTo(@60);
                }];
                [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(@-40);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
                self.localView.hidden = NO;
            } else {
                // 接听方
                self.localView.hidden = YES;
                self.answerButton.hidden = NO;
                [self.hangupButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.centerX.equalTo(self.buttonView);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
                [self.answerButton mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.right.equalTo(@-40);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
                [self.switchToVoice mas_remakeConstraints:^(MASConstraintMaker *make) {
                    make.left.equalTo(@40);
                    make.width.height.equalTo(@60);
                    make.bottom.equalTo(self.buttonView);
                }];
            }
        }
    }
}

- (void)setRemoteEnableVideo:(BOOL)enabled
{
    self.remoteView.model.enableVideo = enabled;
    [self.remoteView update];
}

- (void)setLocalView:(EaseCallStreamView *)localView
{
    _localView = localView;
    [self.contentView insertSubview:localView atIndex:0];
    _localView.model.showUserHeaderURL = [EaseCallManager.sharedManager getHeadImageByUserName:AgoraChatClient.sharedClient.currentUsername];
    localView.delegate = self;
    [_localView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    if (self.type == EaseCallType1v1Video) {
        self.enableCameraButton.selected = YES;
        self.localView.model.enableVideo = YES;
    } else {
        self.localView.model.enableVideo = NO;
        self.localView.hidden = YES;
    }
    [self.localView update];
}

- (void)setRemoteView:(EaseCallStreamView *)remoteView
{
    _remoteView = remoteView;
    remoteView.delegate = self;
    [self.contentView insertSubview:remoteView aboveSubview:_localView];
    [_remoteView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@80);
        make.height.equalTo(@100);
        make.right.equalTo(self.contentView).with.offset(-40);
        make.top.equalTo(self.contentView).with.offset(70);
    }];
    [self updatePos];
}

- (void)answerAction
{
    [super answerAction];
    self.answerButton.hidden = YES;
}

- (void)muteAction
{
    [super muteAction];
    self.localView.model.enableVoice = self.microphoneButton.isSelected;
    [self.localView update];
}

- (void)miniAction
{
    self.isMini = YES;
    EaseCallStreamViewModel *model = self.remoteView.model;
    model.enableVideo = self.type == EaseCallType1v1Video;
    if (self.isConnected) {
        int m = (self.timeLength) / 60;
        int s = self.timeLength - m * 60;
        self.remoteView.model.showUsername = [NSString stringWithFormat:@"%02d:%02d", m, s];
    } else {
        model.showUsername = EaseCallLocalizableString(@"calling",nil);
        model.enableVideo = NO;
    }
    self.remoteView.model.isMini = YES;
    [self.remoteView update];
    
    [self.remoteView removeFromSuperview];
    [UIApplication.sharedApplication.keyWindow addSubview:self.remoteView];
    if (self.isConnected && self.remoteView.model.enableVideo) {
        [self.remoteView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-20);
            make.top.equalTo(@80);
            make.width.equalTo(@90);
            make.height.equalTo(@160);
        }];
    } else {
        [self.remoteView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(@-20);
            make.top.equalTo(@80);
            make.width.equalTo(@76);
            make.height.equalTo(@76);
        }];
    }
    self.remoteView.frame = CGRectMake(self.contentView.bounds.size.width - 100, 80, 80, 100);
    self.remoteView.hidden = NO;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)callFinish
{
    [_remoteView removeFromSuperview];
}

- (void)streamViewDidTap:(EaseCallStreamView *)aVideoView
{
    if (self.isMini) {
        self.isMini = NO;
        self.remoteView.model.isMini = YES;
        [self.remoteView removeFromSuperview];
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        UIViewController *rootViewController = window.rootViewController;
        self.modalPresentationStyle = 0;
        [rootViewController presentViewController:self animated:YES completion:nil];
        if (self.type == EaseCallType1v1Video) {
            self.remoteView.model.enableVideo = YES;
        }
        [self setRemoteView:self.remoteView];
        [self.remoteView update];
        return;
    }
    if (aVideoView.frame.size.width == 80) {
        EaseCallStreamView *otherView = aVideoView == self.localView ? self.remoteView : self.localView;
        [self.contentView sendSubviewToBack:aVideoView];
        [otherView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@80);
            make.height.equalTo(@100);
            make.right.equalTo(self.contentView).with.offset(-40);
            make.top.equalTo(self.contentView).with.offset(70);
        }];
        [aVideoView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.view);
        }];
    }
}

- (void)setLocalDisplayViewEnableVideo:(BOOL)aEnableVideo
{
    if (self.localView) {
        self.localView.delegate = self;
        self.localView.model.enableVideo = aEnableVideo;
        [self.localView update];
        if (!aEnableVideo) {
            self.enableCameraButton.selected = NO;
        }
    }
}

- (void)setRemoteDisplayViewEnableVideo:(BOOL)aEnableVideo
{
    _remoteView.delegate = self;
    _remoteView.model.enableVideo = aEnableVideo;
    _remoteView.model.showUserHeaderURL = [EaseCallManager.sharedManager getHeadImageByUserName:self.remoteUid];
    [_remoteView update];
    if (!aEnableVideo && self.type == EaseCallType1v1Video) {
        [self switchToVoiceAction];
    }
    if (self.type == EaseCallType1v1Video && self.isConnected) {
        [self streamViewDidTap:self.remoteView];
    }
    [self updatePos];
}

- (void)enableVideoAction
{
    [super enableVideoAction];
    self.localView.model.enableVideo = self.enableCameraButton.isSelected;
    [self.localView update];
}

- (void)showTip:(BOOL)enableVoice
{
    NSString *msg = EaseCallLocalizableString(enableVoice ? @"remoteUnmute" : @"remoteMute", nil);
    _tipLabel.alpha = 1.0;
    self.tipLabel.text = msg;
    [UIView animateWithDuration:3 animations:^{
        self.tipLabel.alpha = 0.0;
    }];
}

- (void)setRemoteMute:(BOOL)muted
{
    if (self.remoteView) {
        self.remoteView.model.enableVoice = !muted;
        [self.remoteView update];
    }
}

- (void)setIsConnected:(BOOL)isConnected
{
    _isConnected = isConnected;
    if (isConnected) {
        [self startTimer];
        if (self.isMini && self.type == EaseCallType1v1Video) {
            self.remoteView.model.enableVideo = YES;
            self.remoteView.model.showUsername = EaseCallLocalizableString(@"Call in progress",nil);
            [self.remoteView update];
        }
    }
    if (self.type == EaseCallType1v1Video && isConnected) {
        [self streamViewDidTap:self.remoteView];
    }
    [self updatePos];
}

- (void)usersInfoUpdated
{
    self.remoteNameLable.text = [EaseCallManager.sharedManager getNicknameByUserName:self.remoteUid];
}

- (void)callTimerDidChange:(NSUInteger)min sec:(NSUInteger)sec
{
    [super callTimerDidChange:min sec:sec];
    self.remoteView.model.showUsername = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    [self.remoteView update];
}

@end
