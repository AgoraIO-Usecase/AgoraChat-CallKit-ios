//
//  EaseCallSingleViewController.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallSingleViewController.h"
#import <Masonry/Masonry.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIImage+Ext.h"
#import "AgoraChatCallLocalizable.h"
#import "AgoraChatCallStreamViewModel.h"
#import "AgoraChatCallManager.h"
#import "AgoraChatCallStreamView.h"
#import "AgoraChatCallManager+Private.h"

@import AgoraChat;

@interface AgoraChatCallSingleViewController ()<AgoraChatCallStreamViewDelegate>

@property (nonatomic, assign) CGSize targetSize;
@property (nonatomic, strong) AgoraChatCallStreamView *remoteView;
@property (nonatomic, strong) AgoraChatCallStreamView *localView;
@property (nonatomic, strong) UIButton *recallButton;
@property (nonatomic, strong) UIButton *closeButton;

@property (nonatomic) NSString *remoteUid;
@property (nonatomic) AgoraChatCallType type;

@end

@implementation AgoraChatCallSingleViewController

- (instancetype)initWithisCaller:(BOOL)aIsCaller type:(AgoraChatCallType)aType remoteName:(NSString*)aRemoteName
{
    if (self = [super init]) {
        self.isCaller = aIsCaller;
        self.remoteUid = aRemoteName;
        self.type = aType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.contentView insertSubview:self.remoteView atIndex:0];

    _recallButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_recallButton setImage:[UIImage agoraChatCallKit_imageNamed:@"call_recall"] forState:UIControlStateNormal];
    [_recallButton addTarget:self action:@selector(recallAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_recallButton];

    _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_closeButton setImage:[UIImage agoraChatCallKit_imageNamed:@"call_close"] forState:UIControlStateNormal];
    [_closeButton addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_closeButton];
    
    [_recallButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(@60);
        make.bottom.equalTo(self.buttonView);
        make.width.height.equalTo(@64);
    }];
    
    [_closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(@-60);
        make.bottom.equalTo(self.buttonView);
        make.width.height.equalTo(@64);
    }];
    
    [self.contentView addSubview:self.localView];
    if (self.callState == AgoraChatCallState_Answering) {
        [AgoraChatCallManager.sharedManager setupLocalVideo:_localView.displayView];
    } else {
        [AgoraChatCallManager.sharedManager setupLocalVideo:_remoteView.displayView];
    }
    
    [self updatePos];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.isMini) {
        [self updatePositionToMiniView];
    } else {
        BOOL miniViewEnableVideo = NO;
        if (_remoteView.model.isMini) {
            miniViewEnableVideo = _remoteView.model.enableVideo;
        } else {
            miniViewEnableVideo = _localView.model.enableVideo;
        }
        CGSize size = CGSizeZero;
        if (self.callState == AgoraChatCallState_Answering && miniViewEnableVideo) {
            size.width = 90;
            if (_targetSize.width > 0 && _targetSize.height > 0 && _remoteView.model.isMini) {
                size.height = 90 / _targetSize.width * _targetSize.height;
            } else {
                size.height = 160;
            }
        } else {
            size.width = 76;
            size.height = 76;
        }
        
        CGFloat x = self.contentView.bounds.size.width - 20 - size.width;
        
        if (_remoteView.model.isMini) {
            _localView.frame = self.contentView.bounds;
            _remoteView.frame = CGRectMake(x, 88, size.width, size.height);
        } else {
            _remoteView.frame = self.contentView.bounds;
            _localView.frame = CGRectMake(x, 88, size.width, size.height);
        }
    }
}

- (AgoraChatCallStreamView *)remoteView
{
    if (!_remoteView) {
        _remoteView = [[AgoraChatCallStreamView alloc] init];
        _remoteView.delegate = self;
        
        AgoraChatCallStreamViewModel *remoteModel = [[AgoraChatCallStreamViewModel alloc] init];
        remoteModel.enableVideo = self.callType == AgoraChatCallType1v1Video;
        remoteModel.callType = self.callType;
        remoteModel.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:self.remoteUid];
        remoteModel.showUserHeaderURL = [AgoraChatCallManager.sharedManager getHeadImageByUserName:self.remoteUid];
        
        if (self.isCaller) {
            remoteModel.showStatusText = AgoraChatCallLocalizableString(@"calling",nil);
            self.answerButton.hidden = YES;
        } else {
            if (self.callType == AgoraChatCallType1v1Audio) {
                remoteModel.showStatusText = AgoraChatCallLocalizableString(@"AudioCall",nil);
            } else {
                remoteModel.showStatusText = AgoraChatCallLocalizableString(@"VideoCall",nil);
            }
        }
        _remoteView.model = remoteModel;
    }
    return _remoteView;
}

- (AgoraChatCallStreamView *)localView
{
    if (!_localView && self.callType == AgoraChatCallType1v1Video) {
        AgoraChatCallStreamViewModel *localModel = [[AgoraChatCallStreamViewModel alloc] init];
        localModel.enableVideo = YES;
        localModel.callType = self.callType;
        localModel.isMini = YES;

        _localView = [[AgoraChatCallStreamView alloc] init];
        _localView.delegate = self;
        _localView.hidden = YES;
        _localView.model = localModel;
        NSURL *selfUrl = [AgoraChatCallManager.sharedManager getHeadImageByUserName:AgoraChatClient.sharedClient.currentUsername];
        _localView.model.showUserHeaderURL = selfUrl;
    }
    return _localView;
}

- (void)setCallState:(AgoraChatCallState)callState
{
    [super setCallState:callState];
    
    BOOL isConnected = callState == AgoraChatCallState_Answering;
    
    self.remoteView.model.joined = isConnected;
    self.localView.model.joined = isConnected;
    if (isConnected) {
        [self startTimer];
    }
    if (self.type == AgoraChatCallType1v1Video && isConnected) {
        if (self.isMini) {
            [self updatePositionToMiniView];
        } else {
            [self switchViewToBig:_remoteView];
        }
    }
    [self setupLocalVideo];
    [_remoteView update];
    [_localView update];
    
    [self updatePos];
}

- (void)updatePos
{
    BOOL isConnected = self.callState == AgoraChatCallState_Answering;
    
    if (self.callState == AgoraChatCallState_Unanswered) {
        self.enableCameraButton.hidden = YES;
        self.switchCameraButton.hidden = YES;
        self.microphoneButton.hidden = YES;
        self.speakerButton.hidden = YES;
        self.answerButton.hidden = YES;
        self.hangupButton.hidden = YES;
        
        _recallButton.hidden = NO;
        _closeButton.hidden = NO;
        
        self.remoteView.model.showStatusText = AgoraChatCallLocalizableString(@"NoAnswer",nil);
        [self.remoteView update];
        return;
    }
    
    if (!isConnected) {
        if (self.callType == AgoraChatCallType1v1Audio) {
            self.remoteView.model.showStatusText = AgoraChatCallLocalizableString(@"AudioCall",nil);
        } else {
            self.remoteView.model.showStatusText = AgoraChatCallLocalizableString(@"VideoCall",nil);
        }
        [self.remoteView update];
    }
    
    self.hangupButton.hidden = NO;
    _recallButton.hidden = YES;
    _closeButton.hidden = YES;
    
    if (self.type == AgoraChatCallType1v1Audio) {
        // 音频
        self.enableCameraButton.hidden = YES;
        self.switchCameraButton.hidden = YES;
        
        if (isConnected) {
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
        _localView.hidden = !isConnected;
        
        if (isConnected) {
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
    if (self.remoteView.model.isMini) {
        [self updatePositionToMiniView];
    }
}

- (void)answerAction
{
    [super answerAction];
    self.answerButton.hidden = YES;
}

- (void)didMuteAudio:(BOOL)mute
{
    [super didMuteAudio:mute];
    _localView.model.enableVoice = !mute;
    [_localView update];
}

- (void)miniAction
{
    self.isMini = YES;
    AgoraChatCallStreamViewModel *model = self.remoteView.model;
    if (self.callState == AgoraChatCallState_Answering) {
        int m = (self.timeLength) / 60;
        int s = self.timeLength - m * 60;
        model.showUsername = [NSString stringWithFormat:@"%02d:%02d", m, s];
    } else {
        model.showUsername = AgoraChatCallLocalizableString(@"calling",nil);
    }
    _remoteView.model.isMini = YES;
    _remoteView.panGestureActionEnable = YES;
    [_remoteView update];
    
    [_remoteView removeFromSuperview];
    [[AgoraChatCallManager.sharedManager getKeyWindow] addSubview:_remoteView];
    [self updatePositionToMiniView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateMiniViewPosition
{
    AgoraChatCallMiniViewPosition position;
    UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
    position.isLeft = _remoteView.center.x <= keyWindow.bounds.size.width / 2;
    position.top = _remoteView.frame.origin.y;
    self.miniViewPosition = position;
}

- (void)updatePositionToMiniView
{
    CGFloat x = 20;
    CGSize size;
    if (self.callState == AgoraChatCallState_Answering && self.remoteView.model.enableVideo) {
        size.width = 90;
        if (_targetSize.width > 0 && _targetSize.height > 0) {
            size.height = 90 / _targetSize.width * _targetSize.height;
        } else {
            size.height = 160;
        }
    } else {
        size.width = 76;
        size.height = 76;
    }
    if (!self.miniViewPosition.isLeft) {
        UIWindow *keyWindow = [AgoraChatCallManager.sharedManager getKeyWindow];
        x = keyWindow.bounds.size.width - 20 - size.width;
    }
    _remoteView.frame = CGRectMake(x, self.miniViewPosition.top, size.width, size.height);
}

- (void)dealloc
{
    [_remoteView removeFromSuperview];
}

- (void)streamViewDidTap:(AgoraChatCallStreamView *)aVideoView
{
    if (self.isMini) {
        self.isMini = NO;
        [self updateMiniViewPosition];
        _remoteView.model.isMini = NO;
        _remoteView.panGestureActionEnable = NO;
        _remoteView.model.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:self.remoteUid];
        [self.remoteView removeFromSuperview];
        UIViewController *rootViewController = [AgoraChatCallManager.sharedManager getKeyWindow].rootViewController;
        self.modalPresentationStyle = 0;
        [rootViewController presentViewController:self animated:YES completion:nil];
        [self.contentView insertSubview:_remoteView atIndex:0];
        [_remoteView update];
        [self switchViewToBig:_remoteView];
    } else if (aVideoView.model.isMini) {
        [self switchViewToBig:aVideoView];
    }
}

- (void)switchViewToBig:(AgoraChatCallStreamView *)view
{
    AgoraChatCallStreamView *otherView = view == _localView ? _remoteView : _localView;
    view.model.isMini = NO;
    otherView.model.isMini = YES;
    
    [_localView update];
    [_remoteView update];
    
    [self.contentView sendSubviewToBack:view];
    
    [self.view setNeedsLayout];
}

- (void)streamView:(AgoraChatCallStreamView *)videoView didPan:(UIPanGestureRecognizer *)panGesture
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
    _localView.model.enableVideo = !self.enableCameraButton.isSelected;
    [_localView update];
    [self.view setNeedsLayout];
}

- (void)recallAction
{
    AgoraChatConversation *conversation = [AgoraChatClient.sharedClient.chatManager getConversationWithConvId:self.remoteUserAccount];
    NSString *msgId = conversation.latestMessage.messageId;
    [AgoraChatCallManager.sharedManager startSingleCallWithUId:self.remoteUserAccount type:self.callType ext:nil completion:^(NSString * callId, AgoraChatCallError * aError) {
        
    }];
}

- (void)closeAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
    [AgoraChatCallManager.sharedManager clearRes];
}

- (void)setRemoteMute:(BOOL)muted
{
    if (self.remoteView) {
        self.remoteView.model.enableVoice = !muted;
        [self.remoteView update];
    }
}

- (void)usersInfoUpdated
{
    self.remoteView.model.showUsername = [AgoraChatCallManager.sharedManager getNicknameByUserName:self.remoteUid];
    [self.remoteView updateShowingImageAndUsername];
}

- (void)callTimerDidChange:(NSUInteger)min sec:(NSUInteger)sec
{
    if (self.isMini) {
        self.remoteView.model.showUsername = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    } else {
        self.remoteView.model.showStatusText = [NSString stringWithFormat:@"%02d:%02d", min, sec];
    }
    [self.remoteView updateShowingImageAndUsername];
}

- (void)setupLocalVideo
{
    if (self.callState == AgoraChatCallState_Answering) {
        if (self.localView) {
            [AgoraChatCallManager.sharedManager setupLocalVideo:_localView.displayView];
        }
        [AgoraChatCallManager.sharedManager muteLocalVideoStream:NO];
    } else {
        [AgoraChatCallManager.sharedManager setupLocalVideo:_remoteView.displayView];
    }
}

- (void)setupRemoteVideoView:(NSUInteger)uid size:(CGSize)size
{
    [AgoraChatCallManager.sharedManager setupRemoteVideoView:uid withDisplayView:self.remoteView.displayView];
//    _targetSize = size;
    if (self.viewLoaded) {
        [self.view setNeedsLayout];
    }
}

#pragma mark - IAgoraChatCallIncomingAlertViewShowable
- (NSString *)showAlertTitle
{
    return [AgoraChatCallManager.sharedManager getNicknameByUserName:self.remoteUid];
}

@end
