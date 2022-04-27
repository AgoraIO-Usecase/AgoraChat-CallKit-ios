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

@property (nonatomic,strong) EaseCallStreamView* remoteView;
@property (nonatomic,strong) EaseCallStreamView* localView;

@property (nonatomic) NSString* remoteUid;
@property (nonatomic) EaseCallType type;

@end

@implementation EaseCallSingleViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.isConnected = NO;
    self.isMini = NO;
    
    _remoteView = [[EaseCallStreamView alloc] init];
    _remoteView.delegate = self;
    [self.contentView insertSubview:_remoteView atIndex:0];
    
    EaseCallStreamViewModel *remoteModel = [[EaseCallStreamViewModel alloc] init];
    remoteModel.enableVideo = self.callType == EaseCallType1v1Video;
    remoteModel.callType = self.callType;
    remoteModel.showUsername = [EaseCallManager.sharedManager getNicknameByUserName:self.remoteUid];
    remoteModel.showUserHeaderURL = [EaseCallManager.sharedManager getHeadImageByUserName:self.remoteUid];
    
    if (self.isCaller) {
        remoteModel.showStatusText = EaseCallLocalizableString(@"calling",nil);
        self.answerButton.hidden = YES;
    } else {
        if (self.callType == EaseCallType1v1Audio) {
            remoteModel.showStatusText = EaseCallLocalizableString(@"AudioCall",nil);
        } else {
            remoteModel.showStatusText = EaseCallLocalizableString(@"VideoCall",nil);
        }
    }
    _remoteView.model = remoteModel;
    
    if (self.callType == EaseCallType1v1Video) {
        EaseCallStreamViewModel *localModel = [[EaseCallStreamViewModel alloc] init];
        localModel.enableVideo = YES;
        localModel.callType = self.callType;
        localModel.isMini = YES;

        _localView = [[EaseCallStreamView alloc] init];
        _localView.delegate = self;
        _localView.hidden = YES;
        _localView.model = localModel;
        [self.contentView addSubview:_localView];
        NSURL *selfUrl = [EaseCallManager.sharedManager getHeadImageByUserName:AgoraChatClient.sharedClient.currentUsername];
        _localView.model.showUserHeaderURL = selfUrl;

        [_localView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@80);
            make.height.equalTo(@100);
            make.right.equalTo(self.contentView).with.offset(-40);
            make.top.equalTo(self.contentView).with.offset(70);
        }];
        [EaseCallManager.sharedManager setupLocalVideo:_remoteView.displayView];
    }
    
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.isMini) {
        [self updatePositionToMiniView];
    } else {
        _remoteView.frame = self.contentView.bounds;
    }
}

- (void)updatePos
{
    if (self.type == EaseCallType1v1Audio) {
        // 音频
        self.enableCameraButton.hidden = YES;
        self.switchCameraButton.hidden = YES;
        
        if (_isConnected) {
            // 接通
            self.microphoneButton.hidden = NO;
            self.speakerButton.hidden = NO;
            self.answerButton.hidden = YES;
            
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
        self.enableCameraButton.hidden = NO;
        self.speakerButton.hidden = YES;
        self.switchCameraButton.hidden = NO;
        self.localView.hidden = !_isConnected;
        
        if (_isConnected) {
            self.microphoneButton.hidden = NO;
            self.answerButton.hidden = YES;
            
            [self.enableCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
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
        } else {
            if (_isCaller) {
                self.microphoneButton.hidden = NO;
                self.answerButton.hidden = YES;
                [self.enableCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
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
                
            } else {
                self.microphoneButton.hidden = YES;
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
                [self.enableCameraButton mas_remakeConstraints:^(MASConstraintMaker *make) {
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

- (void)answerAction
{
    [super answerAction];
    self.answerButton.hidden = YES;
}

- (void)muteAction
{
    [super muteAction];
    self.localView.model.enableVoice = !self.microphoneButton.isSelected;
    [self.localView update];
}

- (void)miniAction
{
    self.isMini = YES;
    EaseCallStreamViewModel *model = _remoteView.model;
    model.enableVideo = self.type == EaseCallType1v1Video;
    if (self.isConnected) {
        int m = (self.timeLength) / 60;
        int s = self.timeLength - m * 60;
        model.showUsername = [NSString stringWithFormat:@"%02d:%02d", m, s];
    } else {
        model.showUsername = EaseCallLocalizableString(@"calling",nil);
        model.enableVideo = NO;
    }
    _remoteView.model.isMini = YES;
    _remoteView.panGestureActionEnable = YES;
    [_remoteView update];
    
    [_remoteView removeFromSuperview];
    [UIApplication.sharedApplication.keyWindow addSubview:_remoteView];
    [self updatePositionToMiniView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateMiniViewPosition
{
    EaseCallMiniViewPosition position;
    position.isLeft = _remoteView.center.x <= self.contentView.bounds.size.width / 2;
    position.top = _remoteView.frame.origin.y;
    self.miniViewPosition = position;
}

- (void)updatePositionToMiniView
{
    CGFloat x = 20;
    CGSize size;
    if (self.isConnected && self.remoteView.model.enableVideo) {
        size.width = 90;
        size.height = 160;
    } else {
        size.width = 76;
        size.height = 76;
    }
    if (!self.miniViewPosition.isLeft) {
        x = self.contentView.bounds.size.width - 20 - size.width;
    }
    _remoteView.frame = CGRectMake(x, self.miniViewPosition.top, size.width, size.height);
}

- (void)dealloc
{
    [_remoteView removeFromSuperview];
}

- (void)streamViewDidTap:(EaseCallStreamView *)aVideoView
{
    if (self.isMini) {
        self.isMini = NO;
        [self updateMiniViewPosition];
        _remoteView.model.isMini = NO;
        _remoteView.panGestureActionEnable = NO;
        _remoteView.model.showUsername = [EaseCallManager.sharedManager getNicknameByUserName:self.remoteUid];
        [self.remoteView removeFromSuperview];
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        UIViewController *rootViewController = window.rootViewController;
        self.modalPresentationStyle = 0;
        [rootViewController presentViewController:self animated:YES completion:nil];
        [self.contentView insertSubview:_remoteView atIndex:0];
        [_remoteView update];
        return;
    }
    if (aVideoView.model.isMini) {
        EaseCallStreamView *otherView = aVideoView == self.localView ? self.remoteView : self.localView;
        aVideoView.model.isMini = NO;
        otherView.model.isMini = YES;
        
        [_localView update];
        [_remoteView update];
        
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

- (void)streamView:(EaseCallStreamView *)videoView didPan:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:panGesture.view];
    CGFloat x = 20;
    if (!self.miniViewPosition.isLeft) {
        x = self.contentView.bounds.size.width - videoView.bounds.size.width - 20;
    }
    CGFloat y = self.miniViewPosition.top;
    videoView.frame = CGRectMake(x + translation.x, y + translation.y, videoView.bounds.size.width, videoView.bounds.size.height);
    if (panGesture.state == UIGestureRecognizerStateEnded || panGesture.state == UIGestureRecognizerStateCancelled) {
        [self updateMiniViewPosition];
        [UIView animateWithDuration:0.25 animations:^{
            [self updatePositionToMiniView];
        }];
    }
}

- (void)enableVideoAction
{
    [super enableVideoAction];
    self.localView.model.enableVideo = !self.enableCameraButton.isSelected;
    [self.localView update];
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
    _remoteView.model.joined = YES;
    _localView.model.joined = YES;
    if (isConnected) {
        [self startTimer];
        if (self.isMini && self.type == EaseCallType1v1Video) {
            _remoteView.model.enableVideo = YES;
        }
        [self setupLocalVideo];
    }
    if (self.type == EaseCallType1v1Video && isConnected) {
        [self streamViewDidTap:self.remoteView];
    }
    [_remoteView update];
    [_localView update];
    [self updatePos];
}

- (void)usersInfoUpdated
{
    self.remoteView.model.showUsername = [EaseCallManager.sharedManager getNicknameByUserName:self.remoteUid];
    [self.remoteView updateShowingImageAndUsername];
}

- (void)callTimerDidChange:(NSUInteger)min sec:(NSUInteger)sec
{
    if (self.isMini) {
        self.remoteView.model.showUsername = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    } else {
        self.remoteView.model.showStatusText = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    }
    [self.remoteView update];
}

- (void)setupLocalVideo
{
    if (self.isConnected) {
        if (_localView) {
            [EaseCallManager.sharedManager setupLocalVideo:_localView.displayView];
        }
    } else {
        [EaseCallManager.sharedManager setupLocalVideo:_remoteView.displayView];
    }
}

- (void)setupRemoteVideoView:(NSUInteger)uid
{
    [EaseCallManager.sharedManager setupRemoteVideoView:uid withDisplayView:_remoteView.displayView];
}

@end
