//
//  AgoraChatCallManager.m
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/18.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallManager.h"
#import "AgoraChatCallSingleViewController.h"
#import "AgoraChatCallMultiViewController.h"
#import "AgoraChatCallManager+Private.h"
#import <Masonry/Masonry.h>
#import "AgoraChatCallModal.h"
#import "AgoraChatCallLocalizable.h"

@import CommonCrypto;
@import AudioToolbox;
@import AVFoundation;

static NSString* kAction = @"action";
static NSString* kChannelName = @"channelName";
static NSString* kCallType = @"type";
static NSString* kCallerDevId = @"callerDevId";
static NSString* kCallId = @"callId";
static NSString* kTs = @"ts";
static NSString* kCallDuration = @"callDuration";
static NSString* kMsgType = @"msgType";
static NSString* kCalleeDevId = @"calleeDevId";
static NSString* kCallStatus = @"status";
static NSString* kCallResult = @"result";
static NSString* kInviteAction = @"invite";
static NSString* kAlertAction = @"alert";
static NSString* kConfirmRingAction = @"confirmRing";
static NSString* kCancelCallAction = @"cancelCall";
static NSString* kAnswerCallAction = @"answerCall";
static NSString* kConfirmCalleeAction = @"confirmCallee";
static NSString* kVideoToVoice = @"videoToVoice";
static NSString* kBusyResult = @"busy";
static NSString* kAcceptResult = @"accept";
static NSString* kRefuseresult = @"refuse";
static NSString* kMsgTypeValue = @"rtcCallWithAgora";
static NSString* kExt = @"ext";
#define EMCOMMUNICATE_TYPE @"EMCommunicateType"
#define EMCOMMUNICATE_TYPE_VOICE @"EMCommunicateTypeVoice"
#define EMCOMMUNICATE_TYPE_VIDEO @"EMCommunicateTypeVideo"

NSNotificationName const AGORA_CHAT_CALL_KIT_COMMMUNICATE_RECORD = @"AGORA_CHAT_CALL_KIT_COMMMUNICATE_RECORD";

@interface AgoraChatCallManager ()<AgoraChatManagerDelegate,AgoraRtcEngineDelegate,AgoraChatCallModalDelegate>

@property (nonatomic,strong) AgoraChatCallConfig* config;
@property (nonatomic,weak) id<AgoraChatCallDelegate> delegate;
@property (nonatomic) dispatch_queue_t workQueue;
@property (nonatomic,strong) AVAudioPlayer* audioPlayer;
@property (nonatomic,strong) AgoraChatCallModal* modal;
// 定义 agoraKit 变量
@property (strong, nonatomic) AgoraRtcEngineKit *agoraKit;
// 呼叫方Timer
@property (nonatomic,strong) NSMutableDictionary* callTimerDic;
// 接听方Timer
@property (nonatomic,strong) NSMutableDictionary* alertTimerDic;
@property (nonatomic,weak) NSTimer* confirmTimer;
@property (nonatomic,weak) NSTimer* ringTimer;
@property (nonatomic,strong) AgoraChatCallBaseViewController *callVC;
@property (nonatomic) BOOL bNeedSwitchToVoice;

@end

@implementation AgoraChatCallManager
static AgoraChatCallManager *agoraChatCallManager = nil;

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        agoraChatCallManager = [[AgoraChatCallManager alloc] init];
        agoraChatCallManager.delegate = nil;
        [AgoraChatClient.sharedClient.chatManager addDelegate:agoraChatCallManager delegateQueue:nil];
        agoraChatCallManager.modal = [[AgoraChatCallModal alloc] initWithDelegate:agoraChatCallManager];
        agoraChatCallManager.agoraKit = nil;
    });
    return agoraChatCallManager;
}

- (void)initWithConfig:(AgoraChatCallConfig*)aConfig delegate:(id<AgoraChatCallDelegate>)aDelegate
{
    self.delegate= aDelegate;
    _workQueue = dispatch_queue_create("AgoraChatCallManager.WorkQ", DISPATCH_QUEUE_SERIAL);
    if (aConfig) {
        self.config = aConfig;
    } else {
        self.config = [[AgoraChatCallConfig alloc] init];
    }
    if (!self.agoraKit) {
        self.agoraKit = [AgoraRtcEngineKit sharedEngineWithAppId:self.config.agoraAppId delegate:self];
        [self.agoraKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
        [self.agoraKit setClientRole:AgoraClientRoleBroadcaster];
        [self.agoraKit enableAudioVolumeIndication:1000 smooth:5 report_vad:NO];
    }
    
    self.modal.curUserAccount = AgoraChatClient.sharedClient.currentUsername;
}

- (AgoraChatCallConfig*)getAgoraChatCallConfig
{
    return self.config;
}

- (void)setRTCToken:(NSString*_Nullable)aToken channelName:(NSString*)aChannelName uid:(NSUInteger)aUid
{
    if (self.modal.currentCall && [self.modal.currentCall.channelName isEqualToString:aChannelName]) {
        self.modal.agoraRTCToken = aToken;
        self.modal.agoraUid = aUid;
        [self joinChannel];
    }
}

- (void)setUsers:(NSDictionary<NSNumber*,NSString*>*_Nonnull)aUsers channelName:(NSString*)aChannel
{
    if (aUsers.count > 0 && self.modal.currentCall && [self.modal.currentCall.channelName isEqualToString:aChannel]) {
        self.modal.currentCall.allUserAccounts = [aUsers mutableCopy];
        if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
            NSArray<NSString *> *array = aUsers.allValues;
            for (NSString *username in array) {
                [[self getMultiVC] removePlaceHolderForMember:username];
                [self _stopCallTimer:username];
            }
        }
    }
}

- (int)muteLocalVideoStream:(BOOL)mute;
{
    return [self.agoraKit muteLocalVideoStream:mute];
}

- (int)muteRemoteVideoStream:(NSUInteger)uid mute:(BOOL)mute
{
    return [self.agoraKit muteRemoteVideoStream:uid mute:mute];
}

- (NSMutableDictionary*)callTimerDic
{
    if (!_callTimerDic)
        _callTimerDic = [NSMutableDictionary dictionary];
    return _callTimerDic;
}

- (NSMutableDictionary*)alertTimerDic
{
    if (!_alertTimerDic) {
        _alertTimerDic = [NSMutableDictionary dictionary];
    }
    return _alertTimerDic;
}

- (void)startInviteUsers:(NSArray<NSString *> *)aUsers groupId:(NSString *)groupId callType:(AgoraChatCallType)callType ext:(NSDictionary *)aExt completion:(void(^)(NSString *callId, AgoraChatCallError *))aCompletionBlock {
    if (aUsers.count == 0) {
        NSLog(@"InviteUsers faild!!remoteUid is empty");
        if (aCompletionBlock) {
            AgoraChatCallError* error = [AgoraChatCallError errorWithType:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeInvalidParams description:@"Require remoteUid"];
            aCompletionBlock(nil,error);
        } else {
            [self callBackError:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeInvalidParams description:@"Require remoteUid"];
        }
        return;
    }
    __weak typeof(self) weakself = self;
    dispatch_async(weakself.workQueue, ^{
        if (weakself.modal.currentCall && weakself.callVC) {
            NSLog(@"inviteUsers in group");
            for (NSString *uId in aUsers) {
                if ([weakself.modal.currentCall.allUserAccounts.allValues containsObject:uId]) {
                    continue;
                }
                [weakself sendInviteMsgToCallee:uId type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:nil];
                [weakself _startCallTimer:uId];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[weakself getMultiVC] setPlaceHolderUrl:[weakself getHeadImageByUserName:uId] member:uId];
                });
                if (aCompletionBlock) {
                    aCompletionBlock(weakself.modal.currentCall.callId,nil);
                }
            }
        } else {
            weakself.modal.currentCall = [[AgoraChatCall alloc] init];
            weakself.modal.currentCall.channelName = [[NSUUID UUID] UUIDString];
            weakself.modal.currentCall.callType = callType;
            weakself.modal.currentCall.callId = [[NSUUID UUID] UUIDString];
            weakself.modal.currentCall.isCaller = YES;
            weakself.modal.state = AgoraChatCallState_Answering;
            weakself.modal.currentCall.ext = aExt;
            dispatch_async(dispatch_get_main_queue(), ^{
                for (NSString *uId in aUsers) {
                    [weakself sendInviteMsgToCallee:uId type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:nil];
                    [weakself _startCallTimer:uId];
                    [[weakself getMultiVC] setPlaceHolderUrl:[weakself getHeadImageByUserName:uId] member:uId];
                }
                if (aCompletionBlock) {
                    aCompletionBlock(weakself.modal.currentCall.callId, nil);
                }
            });
        }
    });
}

- (void)startSingleCallWithUId:(NSString*)uId type:(AgoraChatCallType)aType ext:(NSDictionary*)aExt completion:(void (^)(NSString* callId,AgoraChatCallError*))aCompletionBlock {
    if (uId.length <= 0) {
        NSLog(@"makeCall faild!!remoteUid is empty");
        if (aCompletionBlock) {
            AgoraChatCallError *error = [AgoraChatCallError errorWithType:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeInvalidParams description:@"Require remoteUid"];
            aCompletionBlock(nil,error);
        } else {
            [self callBackError:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeInvalidParams description:@"Require remoteUid"];
        }
        return;
    }
    __weak typeof(self) weakself = self;
    dispatch_async(weakself.workQueue, ^{
        AgoraChatCallError * error = nil;
        if ([self isBusy]) {
            NSLog(@"makeCall faild!!current is busy");
            if (aCompletionBlock) {
                error = [AgoraChatCallError errorWithType:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeBusy description:@"current is busy "];
                aCompletionBlock(nil,error);
            } else {
                [self callBackError:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeBusy description:@"current is busy"];
            }
        } else {
            weakself.modal.currentCall = [[AgoraChatCall alloc] init];
            weakself.modal.currentCall.channelName = [[NSUUID UUID] UUIDString];
            weakself.modal.currentCall.remoteUserAccount = uId;
            weakself.modal.currentCall.callType = (AgoraChatCallType)aType;
            weakself.modal.currentCall.callId = [[NSUUID UUID] UUIDString];
            weakself.modal.currentCall.isCaller = YES;
            weakself.modal.state = AgoraChatCallState_Outgoing;
            weakself.modal.currentCall.ext = aExt;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself sendInviteMsgToCallee:uId type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:aCompletionBlock];
                [weakself _startCallTimer:uId];
                //                if(aCompletionBlock)
                //                    aCompletionBlock(weakself.modal.currentCall.callId,error);
            });
        }
    });
}

// 是否处于忙碌状态
- (BOOL)isBusy
{
    return self.modal.currentCall && (self.modal.state != AgoraChatCallState_Idle && self.modal.state != AgoraChatCallState_Refuse);
}

- (void)clearRes
{
    NSLog(@"cleraRes");
    if (self.modal.currentCall) {
        if (self.modal.currentCall.callType != EaseCallType1v1Audio) {
            [self.agoraKit stopPreview];
            [self.agoraKit disableVideo];
        }
        if (self.modal.hasJoinedChannel) {
            dispatch_async(self.workQueue, ^{
                self.modal.hasJoinedChannel = NO;
                [self.agoraKit leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
                    NSLog(@"leaveChannel");
                    //[[EMClient sharedClient] log:@"leaveChannel"];
                }];
            });
        }
    }
    if (self.callVC) {
        if (self.callVC.isMini) {
            [self.callVC callFinish];
            self.callVC = nil;
        } else {
            [self.callVC dismissViewControllerAnimated:NO completion:^{
                self.callVC = nil;
            }];
        }
    }
    NSLog(@"invite timer count:%lu",(unsigned long)self.callTimerDic.count);
    NSArray *timers = [self.callTimerDic allValues];
    for (NSTimer *tm in timers) {
        [tm invalidate];
    }
    [self.callTimerDic removeAllObjects];
    NSArray *alertTimers = [self.alertTimerDic allValues];
    for (NSTimer *tm in alertTimers) {
        [tm invalidate];
    }
    if (self.confirmTimer) {
        [self.confirmTimer invalidate];
        self.confirmTimer = nil;
    }
    if (self.ringTimer) {
        [self.ringTimer invalidate];
        self.ringTimer = nil;
    }
    self.modal.currentCall = nil;
    [self.modal.recvCalls removeAllObjects];
    self.bNeedSwitchToVoice = NO;
}

- (UIWindow *)getKeyWindow
{
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                if (@available(iOS 15.0, *)) {
                    return scene.keyWindow;
                } else {
                    for (UIWindow *window in scene.windows) {
                        if (window.isKeyWindow) {
                            return window;
                        }
                    }
                }
            }
        }
    } else {
        return [UIApplication sharedApplication].keyWindow;
    }
    return nil;
}

- (void)refreshUIOutgoing
{
    if (!self.modal.currentCall) {
        return;
    }
    
    if (!self.callVC) {
        if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
            self.callVC = [[AgoraChatCallMultiViewController alloc] init];
        } else {
            self.callVC = [[AgoraChatCallSingleViewController alloc] initWithisCaller:self.modal.currentCall.isCaller type:self.modal.currentCall.callType remoteName:self.modal.currentCall.remoteUserAccount];
            ((AgoraChatCallSingleViewController *)self.callVC).remoteUserAccount = self.modal.currentCall.remoteUserAccount;
        }
        self.callVC.callType = self.modal.currentCall.callType;
        
        self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
        __weak typeof(self) weakself = self;
        UIWindow *keyWindow = [self getKeyWindow];
        if (!keyWindow) {
            return;
        }
        UIViewController* rootVC = keyWindow.rootViewController;
        [rootVC presentViewController:self.callVC animated:NO completion:^{
            if (weakself.modal.currentCall.callType == EaseCallType1v1Video) {
                [weakself.callVC setupLocalVideo];
            }
        }];
    }
    [self fetchToken];
}

- (void)refreshUIAnswering
{
    if (!self.modal.currentCall) {
        return;
    }
    
    if ((self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) && self.modal.currentCall.isCaller) {
        self.callVC = [[AgoraChatCallMultiViewController alloc] init];
        self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
        self.callVC.callType = self.modal.currentCall.callType;
        UIWindow* keyWindow = [self getKeyWindow];
        if (!keyWindow) {
            return;
        }
        UIViewController* rootVC = keyWindow.rootViewController;
        __weak typeof(self) weakself = self;
        [rootVC presentViewController:self.callVC animated:NO completion:^{
            [weakself.callVC setupLocalVideo];
            [weakself fetchToken];
        }];
    }
    [self _stopRingTimer];
    [self stopSound];
}

- (void)refreshUIAlerting
{
    if (!self.modal.currentCall) {
        return;
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(callDidReceive:inviter:ext:)]) {
        [self.delegate callDidReceive:self.modal.currentCall.callType inviter:self.modal.currentCall.remoteUserAccount ext:self.modal.currentCall.ext];
    }
    [self playSound];
    if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
        self.callVC = [[AgoraChatCallMultiViewController alloc] init];
        [self getMultiVC].inviterId = self.modal.currentCall.remoteUserAccount;
    } else {
        self.callVC = [[AgoraChatCallSingleViewController alloc] initWithisCaller:NO type:self.modal.currentCall.callType remoteName:self.modal.currentCall.remoteUserAccount];
        ((AgoraChatCallSingleViewController *)self.callVC).remoteUserAccount = self.modal.currentCall.remoteUserAccount;
    }
    self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
    self.callVC.callType = self.modal.currentCall.callType;
    [self.callVC showAlert];
    [self _startRingTimer:self.modal.currentCall.callId];
}

- (void)setupVideo {
    [self.agoraKit enableVideo];
    // Default mode is disableVideo
    
    // Set up the configuration such as dimension, frame rate, bit rate and orientation
    [self.agoraKit setVideoEncoderConfiguration:self.config.encoderConfiguration];
}

- (AgoraChatCallSingleViewController*)getSingleVC
{
    return (AgoraChatCallSingleViewController*)self.callVC;
}

- (AgoraChatCallMultiViewController*)getMultiVC
{
    return (AgoraChatCallMultiViewController*)self.callVC;
}

#pragma mark - AgoraChatCallModalDelegate
- (void)callStateWillChangeTo:(AgoraChatCallState)newState from:(AgoraChatCallState)preState
{
    NSLog(@"callState will chageto:%ld from:%ld",newState,(long)preState);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callVC.callState = self.modal.state;
        switch (newState) {
            case AgoraChatCallState_Idle:
                if (preState == AgoraChatCallState_Answering && (self.modal.currentCall.callType == EaseCallType1v1Audio || self.modal.currentCall.callType == EaseCallType1v1Video)) {
                    NSString *callId = self.modal.currentCall.callId;
                    NSString *uid = self.modal.currentCall.remoteUserAccount;
                    NSDictionary *ext = @{
                        kMsgType:kMsgTypeValue,
                        kAction:kCancelCallAction,
                        kCallId:callId,
                        kCallerDevId:self.modal.curDevId,
                        kTs:[self getTs],
                        kCallDuration:@(self.callVC.timeLength),
                    };
                    AgoraChatConversation *conversation = [AgoraChatClient.sharedClient.chatManager getConversationWithConvId:uid];
                    if (conversation) {
                        NSString *text = self.modal.currentCall.callType == EaseCallType1v1Audio ? @"Audio Call Ended" : @"Video Call Ended";
                        AgoraChatTextMessageBody *body = [[AgoraChatTextMessageBody alloc] initWithText:text];
                        AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:uid from:self.modal.curUserAccount to:uid body:body ext:ext];
                        [conversation insertMessage:msg error:nil];
                        
                        [NSNotificationCenter.defaultCenter postNotificationName:@"aaaaaaa" object:nil];
                    }
                }
                [self clearRes];
                break;
            case AgoraChatCallState_Outgoing:
                [self refreshUIOutgoing];
                break;
            case AgoraChatCallState_Alerting:
                [self refreshUIAlerting];
                break;
            case AgoraChatCallState_Answering:
                [self refreshUIAnswering];
                break;
            case AgoraChatCallState_Refuse:
                if (self.modal.state == AgoraChatCallState_Refuse && (self.modal.currentCall.callType == EaseCallType1v1Audio || self.modal.currentCall.callType == EaseCallType1v1Video)) {
                    
                    self.modal.currentCall = nil;
                    
                    NSArray *timers = [self.callTimerDic allValues];
                    for (NSTimer *tm in timers) {
                        [tm invalidate];
                    }
                    [self.callTimerDic removeAllObjects];
                    NSArray *alertTimers = [self.alertTimerDic allValues];
                    for (NSTimer *tm in alertTimers) {
                        [tm invalidate];
                    }
                    if (self.confirmTimer) {
                        [self.confirmTimer invalidate];
                        self.confirmTimer = nil;
                    }
                    if (self.ringTimer) {
                        [self.ringTimer invalidate];
                        self.ringTimer = nil;
                    }
                    
                } else {
                    [self clearRes];
                }
                break;
            default:
                break;
        }
    });
    
}

#pragma mark - EMChatManagerDelegate
- (void)messagesDidReceive:(NSArray *)aMessages
{
    __weak typeof(self) weakself = self;
    dispatch_async(weakself.workQueue, ^{
        for (AgoraChatMessage *msg in aMessages) {
            [weakself _parseMsg:msg];
        }
    });
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages
{
    __weak typeof(self) weakself = self;
    dispatch_async(weakself.workQueue, ^{
        for (AgoraChatMessage *msg in aCmdMessages) {
            [weakself _parseMsg:msg];
        }
    });
}

#pragma mark - sendMessage

//发送呼叫邀请消息
- (void)sendInviteMsgToCallee:(NSString*)aUid type:(AgoraChatCallType)aType callId:(NSString*)aCallId channelName:(NSString*)aChannelName ext:(NSDictionary*)aExt completion:(void (^)(NSString* callId,AgoraChatCallError*))aCompletionBlock
{
    if (aUid.length == 0 || aCallId.length == 0 || aChannelName.length == 0) {
        return;
    }
    NSString *strType = AgoraChatCallLocalizableString(@"voice", nil);
    if (aType == EaseCallTypeMultiVideo) {
        strType = AgoraChatCallLocalizableString(@"conferenece", nil);
    } else if (aType == EaseCallTypeMultiAudio) {
        strType = AgoraChatCallLocalizableString(@"confereneceAudio", nil);
    } else if (aType == EaseCallType1v1Video) {
        strType = AgoraChatCallLocalizableString(@"video", nil);
    }
    AgoraChatTextMessageBody *msgBody = [[AgoraChatTextMessageBody alloc] initWithText:[NSString stringWithFormat: AgoraChatCallLocalizableString(@"inviteInfo", nil), strType]];
    NSMutableDictionary *ext = [@{
        kMsgType:kMsgTypeValue,
        kAction:kInviteAction,
        kCallId:aCallId,
        kCallType:@(aType),
        kCallerDevId:self.modal.curDevId,
        kChannelName:aChannelName,
        kTs:[self getTs]
    } mutableCopy];
    if (aExt && aExt.count > 0) {
        [ext setValue:aExt forKey:kExt];
    }
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:self.modal.curUserAccount to:aUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (aCompletionBlock) {
            aCompletionBlock(weakself.modal.currentCall.callId,nil);
        }
        if (error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
}

// 发送alert消息
- (void)sendAlertMsgToCaller:(NSString*)aCallerUid callId:(NSString*)aCallId devId:(NSString*)aDevId
{
    if (aCallerUid.length == 0 || aCallId.length == 0 || aDevId.length == 0) {
        return;
    }
    AgoraChatCmdMessageBody *msgBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"rtcCall"];
    msgBody.isDeliverOnlineOnly = YES;
    NSDictionary *ext = @{
        kMsgType:kMsgTypeValue,
        kAction:kAlertAction,
        kCallId:aCallId,
        kCalleeDevId:self.modal.curDevId,
        kCallerDevId:aDevId,
        kTs:[self getTs]
    };
    AgoraChatMessage* msg = [[AgoraChatMessage alloc] initWithConversationID:aCallerUid from:self.modal.curUserAccount to:aCallerUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
}

// 发送消息有效确认消息
- (void)sendComfirmRingMsgToCallee:(NSString*)aUid callId:(NSString*)aCallId isValid:(BOOL)aIsCallValid calleeDevId:(NSString*)aCalleeDevId
{
    if (aUid.length == 0 || aCallId.length == 0) {
        return;
    }
    AgoraChatCmdMessageBody *msgBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"rtcCall"];
    msgBody.isDeliverOnlineOnly = YES;
    NSDictionary *ext = @{
        kMsgType:kMsgTypeValue,
        kAction:kConfirmRingAction,
        kCallId:aCallId,
        kCallerDevId:self.modal.curDevId,
        kCallStatus:@(aIsCallValid),
        kTs:[self getTs],
        kCalleeDevId:aCalleeDevId
    };
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:self.modal.curUserAccount to:aUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
}

// 发送取消呼叫消息
- (void)sendCancelCallMsgToCallee:(NSString*)aUid callId:(NSString*)aCallId
{
    if (aUid.length == 0 || aCallId.length == 0) {
        return;
    }
    AgoraChatCmdMessageBody *msgBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"rtcCall"];
    NSDictionary *ext = @{
        kMsgType:kMsgTypeValue,
        kAction:kCancelCallAction,
        kCallId:aCallId,
        kCallerDevId:self.modal.curDevId,
        kTs:[self getTs]
    };
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:self.modal.curUserAccount to:aUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if(error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
}

// 发送Answer消息
- (void)sendAnswerMsg:(NSString*)aCallerUid callId:(NSString*)aCallId result:(NSString*)aResult devId:(NSString*)aDevId
{
    if (aCallerUid.length == 0 || aCallId.length == 0 || aResult.length == 0 || aDevId.length == 0) {
        return;
    }
    AgoraChatCmdMessageBody *msgBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"rtcCall"];
    msgBody.isDeliverOnlineOnly = YES;
    NSMutableDictionary *ext = [@{
        kMsgType:kMsgTypeValue,
        kAction:kAnswerCallAction,
        kCallId:aCallId,
        kCalleeDevId:self.modal.curDevId,
        kCallerDevId:aDevId,
        kCallResult:aResult,
        kTs:[self getTs]
    } mutableCopy];
    if (self.modal.currentCall.callType == EaseCallType1v1Audio && self.bNeedSwitchToVoice) {
        [ext setObject:@YES forKey:kVideoToVoice];
    }
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aCallerUid from:self.modal.curUserAccount to:aCallerUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
    [self _startConfirmTimer:aCallId];
}

// 发送仲裁消息
- (void)sendConfirmAnswerMsgToCallee:(NSString*)aUid callId:(NSString*)aCallId result:(NSString*)aResult devId:(NSString*)aDevId
{
    if (aUid.length == 0 || aCallId.length == 0 || aResult.length == 0 || aDevId.length == 0) {
        return;
    }
    AgoraChatCmdMessageBody *msgBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"rtcCall"];
    msgBody.isDeliverOnlineOnly = YES;
    NSDictionary *ext = @{
        kMsgType:kMsgTypeValue,
        kAction:kConfirmCalleeAction,
        kCallId:aCallId,
        kCallerDevId:self.modal.curDevId,
        kCalleeDevId:aDevId,kCallResult:aResult,
        kTs:[self getTs]
    };
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:self.modal.curUserAccount to:aUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
    if ([aResult isEqualToString:kAcceptResult]) {
        self.modal.state = AgoraChatCallState_Answering;
    }
}

- (NSNumber *)getTs
{
    return @([[NSDate date] timeIntervalSince1970] * 1000);
}

#pragma mark - 解析消息信令

- (void)_parseMsg:(AgoraChatMessage*)aMsg
{
    if (![aMsg.to isEqualToString:AgoraChatClient.sharedClient.currentUsername]) {
        return;
    }
    NSDictionary *ext = aMsg.ext;
    NSString *from = aMsg.from;
    NSString *msgType = [ext objectForKey:kMsgType];
    if (msgType.length == 0) {
        return;
    }
    NSString *callId = [ext objectForKey:kCallId];
    NSString *result = [ext objectForKey:kCallResult];
    NSString *callerDevId = [ext objectForKey:kCallerDevId];
    NSString *calleeDevId = [ext objectForKey:kCalleeDevId];
    NSString *channelname = [ext objectForKey:kChannelName];
    NSNumber *isValid = [ext objectForKey:kCallStatus];
    NSNumber *callType = [ext objectForKey:kCallType];
    NSNumber *isVideoToVoice = [ext objectForKey:kVideoToVoice];
    NSDictionary *callExt = nil;
    id ret = [ext objectForKey:kExt];
    if ([ret isKindOfClass:NSDictionary.class]) {
        callExt = ret;
    }
    __weak typeof(self) weakself = self;
    void (^parseInviteMsgExt)(NSDictionary *) = ^void (NSDictionary *ext) {
        //[[EMClient sharedClient] log:@"parseInviteMsgExt"];
        if (weakself.modal.currentCall && [weakself.modal.currentCall.callId isEqualToString:callId]) {
            return;
        }
        if ([weakself.alertTimerDic objectForKey:callId]) {
            return;
        }
        if ([weakself isBusy]) {
            [weakself sendAnswerMsg:from callId:callId result:kBusyResult devId:callerDevId];
        } else {
            AgoraChatCall *call = [[AgoraChatCall alloc] init];
            call.callId = callId;
            call.isCaller = NO;
            call.callType = (AgoraChatCallType)[callType intValue];
            call.remoteCallDevId = callerDevId;
            call.channelName = channelname;
            call.remoteUserAccount = from;
            call.ext = callExt;
            [weakself.modal.recvCalls setObject:call forKey:callId];
            [weakself sendAlertMsgToCaller:call.remoteUserAccount callId:callId devId:call.remoteCallDevId];
            [weakself _startAlertTimer:callId];
        }
    };
    void (^parseAlertMsgExt)(NSDictionary*) = ^void (NSDictionary* ext) {
        //[[EMClient sharedClient] log:[NSString stringWithFormat:@"parseAlertMsgExt currentCallId:%@,state:%ld",weakself.modal.currentCall.callId,(long)weakself.modal.state]];
        // 判断devId
        if ([weakself.modal.curDevId isEqualToString:callerDevId]) {
            // 判断有效
            if (weakself.modal.currentCall && [weakself.modal.currentCall.callId isEqualToString:callId] && [weakself.callTimerDic objectForKey:from]) {
                [weakself sendComfirmRingMsgToCallee:from callId:callId isValid:YES calleeDevId:calleeDevId];
            } else {
                [weakself sendComfirmRingMsgToCallee:from callId:callId isValid:NO calleeDevId:calleeDevId];
            }
        }
    };
    void (^parseCancelCallMsgExt)(NSDictionary *) = ^void (NSDictionary *ext) {
        //[[EMClient sharedClient] log:[NSString stringWithFormat:@"parseCancelCallMsgExt currentCallId:%@,state:%ld",weakself.modal.currentCall.callId,(long)weakself.modal.state]];
        if (weakself.modal.currentCall && [weakself.modal.currentCall.callId isEqualToString:callId] && !weakself.modal.hasJoinedChannel) {
            [weakself _stopConfirmTimer:callId];
            [weakself _stopAlertTimer:callId];
            [weakself callBackCallEnd:AgoarChatCallEndReasonRemoteCancel];
            weakself.modal.state = AgoraChatCallState_Idle;
            [weakself stopSound];
        } else {
            [weakself.modal.recvCalls removeObjectForKey:callId];
            [weakself _stopAlertTimer:callId];
        }
    };
    void (^parseAnswerMsgExt)(NSDictionary *) = ^void (NSDictionary *ext) {
        //[[EMClient sharedClient] log:[NSString stringWithFormat:@"parseAnswerMsgExt currentCallId:%@,state:%ld",weakself.modal.currentCall.callId,weakself.modal.state]];
        if (weakself.modal.currentCall && [weakself.modal.currentCall.callId isEqualToString:callId] && [weakself.modal.curDevId isEqualToString:callerDevId]) {
            if (weakself.modal.currentCall.callType == EaseCallTypeMultiVideo || weakself.modal.currentCall.callType == EaseCallTypeMultiAudio) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (![result isEqualToString:kAcceptResult]) {
                        [[weakself getMultiVC] removePlaceHolderForMember:from];
                    }
                });
                
                NSTimer *timer = [self.callTimerDic objectForKey:from];
                if (timer) {
                    [self sendConfirmAnswerMsgToCallee:from callId:callId result:result devId:calleeDevId];
                    [timer invalidate];
                    timer = nil;
                    [self.callTimerDic removeObjectForKey:from];
                }
            } else {
                if (weakself.modal.state == AgoraChatCallState_Outgoing) {
                    if ([result isEqualToString:kAcceptResult]) {
                        if (isVideoToVoice && isVideoToVoice.boolValue) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [weakself switchToVoice];
                            });
                        }
                        weakself.modal.state = AgoraChatCallState_Answering;
                    } else {
                        if ([result isEqualToString:kRefuseresult]) {
                            [weakself callBackCallEnd:AgoarChatCallEndReasonRefuse];
                            weakself.modal.state = AgoraChatCallState_Refuse;
                        } else if ([result isEqualToString:kBusyResult]) {
                            [weakself callBackCallEnd:AgoarChatCallEndReasonBusy];
                            weakself.modal.state = AgoraChatCallState_Idle;
                        } else {
                            weakself.modal.state = AgoraChatCallState_Idle;
                        }
                    }
                    [weakself sendConfirmAnswerMsgToCallee:from callId:callId result:result devId:calleeDevId];
                }
            }
        }
    };
    void (^parseConfirmRingMsgExt)(NSDictionary*) = ^void (NSDictionary* ext) {
        //[[EMClient sharedClient] log:[NSString stringWithFormat:@"parseConfirmRingMsgExt currentCallId:%@,state:%ld",weakself.modal.currentCall.callId,weakself.modal.state]];
        if ([weakself.alertTimerDic objectForKey:callId] && [calleeDevId isEqualToString:weakself.modal.curDevId]) {
            [weakself _stopAlertTimer:callId];
            if ([weakself isBusy]) {
                [weakself sendAnswerMsg:from callId:callId result:kBusyResult devId:callerDevId];
                return;
            }
            AgoraChatCall *call = [weakself.modal.recvCalls objectForKey:callId];
            if (call) {
                if ([isValid boolValue]) {
                    weakself.modal.currentCall = call;
                    [weakself.modal.recvCalls removeAllObjects];
                    [weakself _stopAllAlertTimer];
                    weakself.modal.state = AgoraChatCallState_Alerting;
                }
                [weakself.modal.recvCalls removeObjectForKey:callId];
            }
        }
    };
    void (^parseConfirmCalleeMsgExt)(NSDictionary *) = ^void (NSDictionary *ext) {
        if (weakself.modal.state == AgoraChatCallState_Alerting && [weakself.modal.currentCall.callId isEqualToString:callId]) {
            [weakself _stopConfirmTimer:callId];
            if ([weakself.modal.curDevId isEqualToString:calleeDevId]) {
                // 仲裁为自己
                if ([result isEqualToString:kAcceptResult]) {
                    weakself.modal.state = AgoraChatCallState_Answering;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakself.modal.currentCall.callType != EaseCallType1v1Audio && weakself.modal.currentCall.callType != EaseCallTypeMultiAudio) {
                            [weakself.callVC setupLocalVideo];
                        }
                        [weakself fetchToken];
                    });
                }
            } else {
                // 已在其他端处理
                [weakself callBackCallEnd:AgoarChatCallEndReasonHandleOnOtherDevice];
                weakself.modal.state = AgoraChatCallState_Idle;
                [weakself stopSound];
            }
        } else {
            if ([self.modal.recvCalls objectForKey:callId]) {
                [weakself.modal.recvCalls removeObjectForKey:callId];
                [weakself _stopAlertTimer:callId];
            }
        }
    };
    void (^parseVideoToVoiceMsg)(NSDictionary *) = ^void (NSDictionary* ext) {
        if (weakself.modal.currentCall && [weakself.modal.currentCall.callId isEqualToString:callId]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself switchToVoice];
            });
        }
    };
    if ([msgType isEqualToString:kMsgTypeValue]) {
        NSString *action = [ext objectForKey:kAction];
        if ([action isEqualToString:kInviteAction]) {
            parseInviteMsgExt(ext);
        } else if ([action isEqualToString:kAlertAction]) {
            parseAlertMsgExt(ext);
        } else if ([action isEqualToString:kConfirmRingAction]) {
            parseConfirmRingMsgExt(ext);
        } else if ([action isEqualToString:kCancelCallAction]) {
            parseCancelCallMsgExt(ext);
        } else if ([action isEqualToString:kConfirmCalleeAction]) {
            parseConfirmCalleeMsgExt(ext);
        } else if ([action isEqualToString:kAnswerCallAction]) {
            parseAnswerMsgExt(ext);
        } else if ([action isEqualToString:kVideoToVoice]) {
            parseVideoToVoiceMsg(ext);
        }
    }
}

#pragma mark - Timer Manager
- (void)_startCallTimer:(NSString*)aRemoteUser
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if([weakself.callTimerDic objectForKey:aRemoteUser])
            return;
        NSLog(@"_startCallTimer,user:%@",aRemoteUser);
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:self.config.callTimeOut target:weakself selector:@selector(_timeoutCall:) userInfo:aRemoteUser repeats:NO];
        [weakself.callTimerDic setObject:timer forKey:aRemoteUser];
    });
}

- (void)_stopCallTimer:(NSString*)aRemoteUser
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *tm = [weakself.callTimerDic objectForKey:aRemoteUser];
        if (tm) {
            NSLog(@"stopCallTimer:%@",aRemoteUser);
            [tm invalidate];
            [weakself.callTimerDic removeObjectForKey:aRemoteUser];
        }
    });
}

- (void)_timeoutCall:(NSTimer*)timer
{
    NSString *aRemoteUser = (NSString*)[timer userInfo];
    NSLog(@"_timeoutCall,user:%@",aRemoteUser);
    [self.callTimerDic removeObjectForKey:aRemoteUser];
    [self sendCancelCallMsgToCallee:aRemoteUser callId:self.modal.currentCall.callId];
    if (self.modal.currentCall.callType != EaseCallTypeMultiVideo && self.modal.currentCall.callType != EaseCallTypeMultiAudio) {
        [self callBackCallEnd:AgoarChatCallEndReasonRemoteNoResponse];
        self.modal.state = AgoraChatCallState_Idle;
    } else {
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[weakself getMultiVC] removePlaceHolderForMember:aRemoteUser];
        });
    }
}

- (void)_startAlertTimer:(NSString*)callId
{
    NSLog(@"_startAlertTimer,callId:%@",callId);
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *tm = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_timeoutAlert:) userInfo:callId repeats:NO];
        [weakself.alertTimerDic setObject:tm forKey:callId];
    });
}

- (void)_stopAlertTimer:(NSString*)callId
{
    NSLog(@"_stopAlertTimer,callId:%@",callId);
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *tm = [weakself.alertTimerDic objectForKey:callId];
        if (tm) {
            [tm invalidate];
            [weakself.alertTimerDic removeObjectForKey:callId];
        }
    });
}

- (void)_stopAllAlertTimer
{
    NSLog(@"_stopAllAlertTimer");
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *tms = [weakself.alertTimerDic allValues];
        for (NSTimer *tm in tms) {
            [tm invalidate];
        }
        [weakself.alertTimerDic removeAllObjects];
    });
}

- (void)_timeoutAlert:(NSTimer*)tm
{
    NSString* callId = (NSString*)[tm userInfo];
    NSLog(@"_timeoutAlert,callId:%@",callId);
    [self.alertTimerDic removeObjectForKey:callId];
}

- (void)_startConfirmTimer:(NSString*)callId
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(weakself.confirmTimer) {
            [weakself.confirmTimer invalidate];
        }
        weakself.confirmTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(_timeoutConfirm:) userInfo:callId repeats:NO];
    });
}

- (void)_stopConfirmTimer:(NSString*)callId
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.confirmTimer) {
            [weakself.confirmTimer invalidate];
            weakself.confirmTimer = nil;
        }
    });
}

- (void)_timeoutConfirm:(NSTimer*)tm
{
    NSString *callId = (NSString*)[tm userInfo];
    NSLog(@"_timeoutConfirm,callId:%@",callId);
    if (self.modal.currentCall && [self.modal.currentCall.callId isEqualToString:callId]) {
        [self callBackCallEnd:AgoarChatCallEndReasonRemoteNoResponse];
        self.modal.state = AgoraChatCallState_Idle;
    }
}

- (void)_startRingTimer:(NSString*)callId
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.ringTimer) {
            [weakself.ringTimer invalidate];
        }
        weakself.ringTimer = [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(_timeoutRing:) userInfo:callId repeats:NO];
    });
}

- (void)_stopRingTimer
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.ringTimer) {
            [weakself.ringTimer invalidate];
            weakself.ringTimer = nil;
        }
    });
}

- (void)_timeoutRing:(NSTimer*)tm
{
    NSString *callId = (NSString*)[tm userInfo];
    NSLog(@"_timeoutConfirm,callId:%@",callId);
    [self stopSound];
    if (self.modal.currentCall && [self.modal.currentCall.callId isEqualToString:callId]) {
        [self callBackCallEnd:AgoarChatCallEndReasonNoResponse];
        self.modal.state = AgoraChatCallState_Idle;
    }
}

#pragma mark - 铃声控制

- (AVAudioPlayer *)audioPlayer
{
    if (!_audioPlayer && _config.ringFileUrl) {
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_config.ringFileUrl error:nil];
        _audioPlayer.numberOfLoops = -1;
        [_audioPlayer prepareToPlay];
    }
    return _audioPlayer;
}

// 播放铃声
- (void)playSound
{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    AVAudioSession*session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    [session setActive:YES error:nil];
    
    [self.audioPlayer play];
}

// 停止播放铃声
- (void)stopSound
{
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
}

#pragma mark - AgoraRtcEngineKitDelegate
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOccurError:(AgoraErrorCode)errorCode
{
    NSLog(@"rtcEngine didOccurError:%ld",(long)errorCode);
    if (errorCode == AgoraErrorCodeTokenExpired || errorCode == AgoraErrorCodeInvalidToken) {
        self.modal.state = AgoraChatCallState_Idle;
        [self callBackError:AgoarChatCallErrorTypeRTC code:errorCode description:@"RTC Error"];
    } else {
        if (errorCode != AgoraErrorCodeNoError && errorCode != AgoraErrorCodeLeaveChannelRejected) {
            [self callBackError:AgoarChatCallErrorTypeRTC code:errorCode description:@"RTC Error"];
        }
    }
}

// 远程音频质量数据
- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteAudioStats:(AgoraRtcRemoteAudioStats *)stats
{
    
}

// 加入频道成功
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinChannel:(NSString *)channel withUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    NSLog(@"join channel success!!! channel:%@,uid:%lu",channel,(unsigned long)uid);
}

// 注册账户成功
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didRegisteredLocalUser:(NSString *)userAccount withUid:(NSUInteger)uid
{
    
}

//token即将过期
- (void)rtcEngine:(AgoraRtcEngineKit *)engine tokenPrivilegeWillExpire:(NSString *)token
{
    // token即将过期，需要重新获取
}

// token 已过期
- (void)rtcEngineRequestToken:(AgoraRtcEngineKit * _Nonnull)engine
{
    
}

// 对方退出频道
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"didOfflineOfUid uid:%lu,reason:%lu",(unsigned long)uid,reason]];
    if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
        [[self getMultiVC] removeRemoteViewForUser:@(uid)];
        [self.modal.currentCall.allUserAccounts removeObjectForKey:@(uid)];
    } else {
        [self callBackCallEnd:AgoarChatCallEndReasonHangup];
        self.modal.state = AgoraChatCallState_Idle;
    }
}

// 对方加入频道
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"didJoinedOfUid:%lu",(unsigned long)uid]];
    if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
        [[self getMultiVC] addMember:@(uid) enableVideo:self.modal.currentCall.callType == EaseCallTypeMultiVideo];
        NSString *username = [self.modal.currentCall.allUserAccounts objectForKey:@(uid)];
        if (username.length > 0) {
            if ([self.callTimerDic objectForKey:username]) {
                [self _stopCallTimer:username];
            }
            [[self getMultiVC] removePlaceHolderForMember:username];
            [[self getMultiVC] setRemoteViewNickname:[self getNicknameByUserName:username] headImage:[self getHeadImageByUserName:username] uId:@(uid)];
        }
    } else {
        [self getSingleVC].isConnected = YES;
        [self _stopCallTimer:self.modal.currentCall.remoteUserAccount];
        [self.modal.currentCall.allUserAccounts setObject:self.modal.currentCall.remoteUserAccount forKey:@(uid)];
    }
    if ([self.delegate respondsToSelector:@selector(remoteUserDidJoinChannel:uid:username:)]) {
        NSString *username = [self.modal.currentCall.allUserAccounts objectForKey:@(uid)];
        [self.delegate remoteUserDidJoinChannel:self.modal.currentCall.channelName uid:uid username:username];
    }
}

// 对方关闭/打开视频
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid
{
    if (self.modal.currentCall.callType == EaseCallTypeMultiVideo) {
        [[self getMultiVC] setRemoteEnableVideo:!muted uId:@(uid)];
    } else if (self.modal.currentCall.callType == EaseCallType1v1Video) {
        [[self getSingleVC] setRemoteEnableVideo:!muted];
    }
}

// 对方打开/关闭音频
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid
{
    if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
        [[self getMultiVC] setRemoteMute:muted uid:@(uid)];
    } else {
        [[self getSingleVC] setRemoteMute:muted];
    }
}

// 对方发视频流
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed
{
    [self.callVC setupRemoteVideoView:uid size:size];
    //[[EMClient sharedClient] log:[NSString stringWithFormat:@"firstRemoteVideoDecodedOfUid:%lu",uid]];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteAudioFrameOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    NSLog(@"firstRemoteAudioFrameOfUid:%lu",(unsigned long)uid);
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine remoteVideoStateChangedOfUid:(NSUInteger)uid state:(AgoraVideoRemoteState)state reason:(AgoraVideoRemoteStateReason)reason elapsed:(NSInteger)elapsed
{
    NSLog(@"staate:%d,reason:%d",state,reason);
//    if (reason == AgoraVideoRemoteStateReasonRemoteMuted && self.modal.currentCall.callType == EaseCallType1v1Video) {
//        __weak typeof(self) weakself = self;
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakself switchToVoice];
//        });
//    }
}

// 谁在说话的回调
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> * _Nonnull)speakers totalVolume:(NSInteger)totalVolume
{
    if (self.agoraKit != engine) {
        return;
    }
    if (self.modal.currentCall && (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio)) {
        for (AgoraRtcAudioVolumeInfo *speakerInfo in speakers) {
            if (speakerInfo.volume > 5) {
                [[self getMultiVC] setUser:speakerInfo.uid isTalking:YES];
            }
        }
    }
}

#pragma mark - 提供delegate

- (void)callBackCallEnd:(AgoarChatCallEndReason)reason
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(callDidEnd:reason:time:type:)]) {
            [weakself.delegate callDidEnd:weakself.modal.currentCall.channelName reason:reason time:weakself.callVC.timeLength type:weakself.modal.currentCall.callType];
        }
    });
}

- (void)callBackError:(AgoarChatCallErrorType)aErrorType code:(NSInteger)aCode description:(NSString*)aDescription
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.delegate && [weakself.delegate respondsToSelector:@selector(callDidOccurError:)]) {
            AgoraChatCallError* error = [AgoraChatCallError errorWithType:aErrorType code:aCode description:aDescription];
            [weakself.delegate callDidOccurError:error];
        }
    });
}


#pragma mark - 获取token
- (void)fetchToken {
    if (self.config.enableRTCTokenValidate) {
        if ([self.delegate respondsToSelector:@selector(callDidRequestRTCTokenForAppId:channelName:account:uid:)]) {
            self.modal.agoraUid = arc4random();
            [self.delegate callDidRequestRTCTokenForAppId:self.config.agoraAppId channelName:self.modal.currentCall.channelName account:AgoraChatClient.sharedClient.currentUsername uid:self.config.agoraUid];
        } else {
            NSLog(@"Warning: You have not implement interface callDidRequestRTCTokenForAppId:channelName:account:!!!!");
        }
    } else {
        [self setRTCToken:nil channelName:self.modal.currentCall.channelName uid:arc4random()];
    }
}

@end


@implementation AgoraChatCallManager (Private)

- (void)hangupAction
{
    NSLog(@"hangupAction,curState:%ld",(long)self.modal.state);
    if (self.modal.state == AgoraChatCallState_Answering) {
        // 正常挂断
        if (self.modal.currentCall.callType == EaseCallTypeMultiVideo || self.modal.currentCall.callType == EaseCallTypeMultiAudio) {
            if (self.callTimerDic.count > 0) {
                NSArray* tmArray = [self.callTimerDic allValues];
                for (NSTimer * tm in tmArray) {
                    [tm fire];
                }
                [self.callTimerDic removeAllObjects];
            }
        }
        
        [self callBackCallEnd:AgoarChatCallEndReasonHangup];
        self.modal.state = AgoraChatCallState_Idle;
    } else if (self.modal.state == AgoraChatCallState_Outgoing) {
        // 取消呼叫
        [self _stopCallTimer:self.modal.currentCall.remoteUserAccount];
        [self sendCancelCallMsgToCallee:self.modal.currentCall.remoteUserAccount callId:self.modal.currentCall.callId];
        [self callBackCallEnd:AgoarChatCallEndReasonCancel];
        self.modal.state = AgoraChatCallState_Idle;
    } else if (self.modal.state == AgoraChatCallState_Alerting) {
        // 拒绝
        [self stopSound];
        [self sendAnswerMsg:self.modal.currentCall.remoteUserAccount callId:self.modal.currentCall.callId result:kRefuseresult devId:self.modal.currentCall.remoteCallDevId];
        [self callBackCallEnd:AgoarChatCallEndReasonRefuse];
        self.modal.state = AgoraChatCallState_Idle;
    }
}

- (void)acceptAction
{
    [self stopSound];
    [self sendAnswerMsg:self.modal.currentCall.remoteUserAccount callId:self.modal.currentCall.callId result:kAcceptResult devId:self.modal.currentCall.remoteCallDevId];
}

- (void)switchCameraAction
{
    [self.agoraKit switchCamera];
}

- (void)inviteAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiCallDidInvitingWithCurVC:callType:excludeUsers:ext:)]){
        NSMutableArray *array = [NSMutableArray array];
        NSArray<NSNumber *> *uids = [[self getMultiVC] getAllUserIds];
        for (NSNumber *uid in uids) {
            NSString *username = [self.modal.currentCall.allUserAccounts objectForKey:uid];
            if (username.length > 0) {
                [array addObject:username];
            }
        }
        NSArray *invitingMems = [self.callTimerDic allKeys];
        [array addObjectsFromArray:invitingMems];
        [self.delegate multiCallDidInvitingWithCurVC:self.callVC callType:self.modal.currentCall.callType excludeUsers:array ext:self.modal.currentCall.ext];
    }
}

- (void)muteAudio:(BOOL)aMuted
{
    [self.agoraKit muteLocalAudioStream:aMuted];
}

- (void)speakeOut:(BOOL)aEnable
{
    [self.agoraKit setEnableSpeakerphone:aEnable];
}

- (NSString *)getNicknameByUserName:(NSString*)aUserName
{
    if (aUserName.length > 0) {
        AgoraChatCallUser *user = [self.config.users objectForKey:aUserName];
        if (user && user.nickName.length > 0) {
            return user.nickName;
        }
    }
    return aUserName;
}
- (NSURL *)getHeadImageByUserName:(NSString *)aUserName
{
    if ([aUserName length] > 0) {
        AgoraChatCallUser *user = [self.config.users objectForKey:aUserName];
        if (user && user.headImage.absoluteString.length > 0) {
            return user.headImage;
        }
    }
    return nil;
}

- (NSString*)getUserNameByUid:(NSNumber *)uId
{
    if (self.modal.currentCall && self.modal.currentCall.allUserAccounts.count > 0) {
        NSString *username = [self.modal.currentCall.allUserAccounts objectForKey:uId];
        if (username.length > 0) {
            return username;
        }
    }
    return nil;
}

- (void)setupRemoteVideoView:(NSUInteger)uid withDisplayView:(UIView *)view
{
    AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
    canvas.uid = uid;
    canvas.renderMode = AgoraVideoRenderModeFit;
    canvas.view = view;
    [self.agoraKit setupRemoteVideo:canvas];
}

- (void)startPreview
{
    [self.agoraKit startPreview];
}

- (void)setupLocalVideo:(UIView *)displayView
{
    AgoraCameraCapturerConfiguration *cameraConfig = [[AgoraCameraCapturerConfiguration alloc] init];
    cameraConfig.cameraDirection = AgoraCameraDirectionFront;
    [self.agoraKit setCameraCapturerConfiguration:cameraConfig];
    [self setupVideo];
    AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
    canvas.uid = 0;
    canvas.renderMode = AgoraVideoRenderModeFit;
    canvas.view = displayView;
    [self.agoraKit setupLocalVideo:canvas];
    if (displayView) {
        [self.agoraKit startPreview];
    } else {
        [self.agoraKit stopPreview];
    }
    [self.agoraKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    [self.agoraKit setClientRole:AgoraClientRoleBroadcaster];
}

- (void)joinChannel
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.modal.hasJoinedChannel) {
            [weakself.agoraKit leaveChannel:nil];
        }
        [weakself.agoraKit joinChannelByToken:weakself.modal.agoraRTCToken channelId:weakself.modal.currentCall.channelName info:@"" uid:self.modal.agoraUid joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
            NSLog(@"join success");
            if ([weakself.delegate respondsToSelector:@selector(callDidJoinChannel:uid:)]) {
                [weakself.delegate callDidJoinChannel:channel uid:uid];
            }
            weakself.modal.hasJoinedChannel = YES;
            [weakself.modal.currentCall.allUserAccounts setObject:AgoraChatClient.sharedClient.currentUsername forKey:@(uid)];
            if (weakself.modal.currentCall.callType == EaseCallTypeMultiVideo || weakself.modal.currentCall.callType == EaseCallTypeMultiAudio) {
                [weakself muteLocalVideoStream:YES];
            }
        }];
        
        [weakself speakeOut:YES];
    });
}

@end