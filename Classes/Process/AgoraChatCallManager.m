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
#import "AgoraChatCallManager+CallKit.h"
#import "UIWindow+AgoraChatCallKit.h"
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

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

@property (nonatomic, strong) NSString *iosCallKitAcceptCallId;

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

- (void)initWithConfig:(AgoraChatCallConfig *)aConfig delegate:(id<AgoraChatCallDelegate>)aDelegate
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
        [self.agoraKit enableAudioVolumeIndication:1000 smooth:5 reportVad:NO];
        
        AgoraCameraCapturerConfiguration *cameraConfig = [[AgoraCameraCapturerConfiguration alloc] init];
        cameraConfig.cameraDirection = AgoraCameraDirectionFront;
        [self.agoraKit setCameraCapturerConfiguration:cameraConfig];
            
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    
    [self initCallKit];
    
    if (AgoraChatCallManager.sharedManager.getAgoraChatCallConfig.enableIosCallKit) {
        [self requestPushKitToken];
    }
}

- (AgoraChatCallConfig *)getAgoraChatCallConfig
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
        dispatch_async(dispatch_get_main_queue(), ^{
            self.modal.currentCall.allUserAccounts = [aUsers mutableCopy];
            [self.callVC usersInfoUpdated];
        });
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

- (NSArray<NSString *> *)getJoinedUsernameList
{
    NSMutableArray *usernameList = [NSMutableArray array];
    NSArray<NSNumber *> *uids = [[self getMultiVC] getAllUserIds];
    for (NSNumber *uid in uids) {
        NSString *username = self.modal.currentCall.allUserAccounts[uid];
        if (username.length > 0) {
            [usernameList addObject:username];
        }
    }
    return usernameList;
}

- (void)startInviteUsers:(NSArray<NSString *> *)aUsers groupId:(NSString *)groupId callType:(AgoraChatCallType)callType ext:(NSDictionary *)aExt completion:(void(^)(NSString *callId, AgoraChatCallError *))aCompletionBlock {
    if (aUsers.count == 0) {
        [AgoraChatClient.sharedClient log:@"InviteUsers faild!!remoteUid is empty"];
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
        if (weakself.modal.currentCall && weakself.callVC) {
            [AgoraChatClient.sharedClient log:@"inviteUsers in group"];
            NSArray<NSString *> *joinedUsernameList = [self getJoinedUsernameList];
            
            for (NSString *uId in aUsers) {
                if ([joinedUsernameList containsObject:uId]) {
                    continue;
                }
                [weakself sendInviteMsgToCallee:uId isGroup:NO type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:nil];
                [weakself _startCallTimer:uId];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[weakself getMultiVC] setPlaceHolderUrl:[weakself getHeadImageByUserName:uId] member:uId];
                });
                if (aCompletionBlock) {
                    aCompletionBlock(weakself.modal.currentCall.callId,nil);
                }
            }
        } else {
            NSUUID *uuid = [NSUUID UUID];
            weakself.modal.currentCall = [[AgoraChatCall alloc] init];
            weakself.modal.currentCall.channelName = [uuid UUIDString];
            weakself.modal.currentCall.callType = callType;
            weakself.modal.currentCall.callId = [uuid UUIDString];
            weakself.modal.currentCall.isCaller = YES;
            weakself.modal.state = AgoraChatCallState_Answering;
            weakself.modal.currentCall.ext = aExt;
            dispatch_async(dispatch_get_main_queue(), ^{
                for (NSString *uId in aUsers) {
                    [weakself sendInviteMsgToCallee:uId isGroup:NO type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:nil];
                    [weakself _startCallTimer:uId];
                    [[weakself getMultiVC] setPlaceHolderUrl:[weakself getHeadImageByUserName:uId] member:uId];
                }
                if (aCompletionBlock) {
                    aCompletionBlock(weakself.modal.currentCall.callId, nil);
                }
                
                [weakself sendInviteMsgToCallee:groupId isGroup:YES type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:^(NSString *callId, AgoraChatCallError *error) {
                    
                }];
            });
        }
    });
}

- (void)startSingleCallWithUId:(NSString*)uId type:(AgoraChatCallType)aType ext:(NSDictionary*)aExt completion:(void (^)(NSString* callId,AgoraChatCallError*))aCompletionBlock {
    if (uId.length <= 0) {
        [AgoraChatClient.sharedClient log:@"makeCall faild!!remoteUid is empty"];
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
            [AgoraChatClient.sharedClient log:@"makeCall faild!!current is busy"];
            if (aCompletionBlock) {
                error = [AgoraChatCallError errorWithType:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeBusy description:@"current is busy "];
                aCompletionBlock(nil,error);
            } else {
                [self callBackError:AgoarChatCallErrorTypeProcess code:AgoraChatCallProcessErrorCodeBusy description:@"current is busy"];
            }
        } else {
            NSUUID *uuid = [NSUUID UUID];
            weakself.modal.currentCall = [[AgoraChatCall alloc] init];
            weakself.modal.currentCall.channelName = [uuid UUIDString];
            weakself.modal.currentCall.remoteUserAccount = uId;
            weakself.modal.currentCall.callType = (AgoraChatCallType)aType;
            weakself.modal.currentCall.callId = [uuid UUIDString];
            weakself.modal.currentCall.isCaller = YES;
            weakself.modal.state = AgoraChatCallState_Outgoing;
            weakself.modal.currentCall.ext = aExt;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself sendInviteMsgToCallee:uId isGroup:NO type:weakself.modal.currentCall.callType callId:weakself.modal.currentCall.callId channelName:weakself.modal.currentCall.channelName ext:aExt completion:aCompletionBlock];
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
    return self.modal.currentCall && (self.modal.state != AgoraChatCallState_Idle && self.modal.state != AgoraChatCallState_Unanswered);
}

- (void)clearRes
{
    [self clearResWithViewController:YES];
}

- (void)clearResWithViewController:(BOOL)withViewController
{
    [AgoraChatClient.sharedClient log:@"cleraRes"];
    dispatch_async(self.workQueue, ^{
        self.modal.hasJoinedChannel = NO;
        [self.agoraKit leaveChannel:^(AgoraChannelStats * _Nonnull stat) {
            [AgoraChatClient.sharedClient log:@"leaveChannel"];
            //[[EMClient sharedClient] log:@"leaveChannel"];
        }];
    });
    
    if (withViewController) {
        [self.agoraKit stopPreview];
        [self.agoraKit disableVideo];
        if (self.callVC) {
            if (self.callVC.isMini) {
                [self.callVC callFinish];
            } else {
                [self.callVC dismissViewControllerAnimated:NO completion:nil];
            }
            self.callVC = nil;
        }
    }
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"invite timer count:%lu",(unsigned long)self.callTimerDic.count]];
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
    
    // 通话结束后，重置麦克风状态
    [self muteAudio:NO];
    // 通话结束后，重置摄像头
    AgoraCameraCapturerConfiguration *cameraConfig = [[AgoraCameraCapturerConfiguration alloc] init];
    cameraConfig.cameraDirection = AgoraCameraDirectionFront;
    [self.agoraKit setCameraCapturerConfiguration:cameraConfig];
}

- (void)refreshUIOutgoing
{
    if (!self.modal.currentCall) {
        return;
    }
    
    if (self.callVC) {
        [self.callVC dismissViewControllerAnimated:NO completion:nil];
        self.callVC = nil;
    }
    if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
        self.callVC = [[AgoraChatCallMultiViewController alloc] initWithCallType:self.modal.currentCall.callType];
    } else {
        self.callVC = [[AgoraChatCallSingleViewController alloc] initWithisCaller:self.modal.currentCall.isCaller type:self.modal.currentCall.callType remoteName:self.modal.currentCall.remoteUserAccount];
        ((AgoraChatCallSingleViewController *)self.callVC).remoteUserAccount = self.modal.currentCall.remoteUserAccount;
    }
    self.callVC.callType = self.modal.currentCall.callType;
    
    self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
    __weak typeof(self) weakself = self;
    UIWindow *keyWindow = UIWindow.agoraChatCallKit_keyWindow;
    if (!keyWindow) {
        return;
    }
    UIViewController* rootVC = keyWindow.rootViewController;
    [rootVC presentViewController:self.callVC animated:NO completion:^{
        if (weakself.modal.currentCall.callType == AgoraChatCallType1v1Video) {
            [weakself.callVC setupLocalVideo];
        }
    }];
    [self fetchToken];
}

- (void)refreshUIAnswering
{
    if (!self.modal.currentCall) {
        return;
    }
    
    if ((self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) && self.modal.currentCall.isCaller) {
        self.callVC = [[AgoraChatCallMultiViewController alloc] initWithCallType:self.modal.currentCall.callType];
        self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
        self.callVC.callType = self.modal.currentCall.callType;
        UIWindow* keyWindow = UIWindow.agoraChatCallKit_keyWindow;
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
    
    if (self.config.enableIosCallKit) {
        [self reportNewIncomingCall:self.modal.currentCall];
        if (self.callVC) {
            [self.callVC dismissViewControllerAnimated:NO completion:nil];
            self.callVC = nil;
        }
    } else {
        if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
            self.callVC = [[AgoraChatCallMultiViewController alloc] initWithCallType:self.modal.currentCall.callType];
            [self getMultiVC].inviterId = self.modal.currentCall.remoteUserAccount;
        } else {
            self.callVC = [[AgoraChatCallSingleViewController alloc] initWithisCaller:NO type:self.modal.currentCall.callType remoteName:self.modal.currentCall.remoteUserAccount];
            ((AgoraChatCallSingleViewController *)self.callVC).remoteUserAccount = self.modal.currentCall.remoteUserAccount;
        }
        self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
        self.callVC.callType = self.modal.currentCall.callType;
        [self playSound];
        [self.callVC showAlert];
    }
    [self _startRingTimer:self.modal.currentCall.callId];
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
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"callState will chageto:%ld from:%ld",newState,(long)preState]];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callVC.callState = newState;
        switch (newState) {
            case AgoraChatCallState_Idle:
                if (preState == AgoraChatCallState_Answering) {
                    NSString *callId = self.modal.currentCall.callId;
                    
                    NSString *conversationId = @"";
                    AgoraChatCallType callType = self.modal.currentCall.callType;
                    if (callType == AgoraChatCallType1v1Video || callType == AgoraChatCallType1v1Audio) {
                        conversationId = self.modal.currentCall.remoteUserAccount;
                    } else {
                        conversationId = self.modal.currentCall.ext[@"groupId"];
                    }
                    if (conversationId.length > 0) {
                        NSDictionary *ext = @{
                            kMsgType:kMsgTypeValue,
                            kAction:kCancelCallAction,
                            kCallId:callId,
                            kCallerDevId:self.modal.curDevId,
                            kTs:[self getTs],
                            kCallType:@(self.modal.currentCall.callType),
                            kCallDuration:@(self.callVC.timeLength),
                        };
                        AgoraChatConversation *conversation = [AgoraChatClient.sharedClient.chatManager getConversationWithConvId:conversationId];
                        if (conversation) {
                            NSString *text = self.modal.currentCall.callType == AgoraChatCallType1v1Audio || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio ? @"Audio Call Ended" : @"Video Call Ended";
                            AgoraChatTextMessageBody *body = [[AgoraChatTextMessageBody alloc] initWithText:text];
                            AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:conversationId from:AgoraChatClient.sharedClient.currentUsername to:conversationId body:body ext:ext];
                            msg.isRead = YES;
                            [conversation insertMessage:msg error:nil];
                            [NSNotificationCenter.defaultCenter postNotificationName:AGORA_CHAT_CALL_KIT_COMMMUNICATE_RECORD object:@{
                                @"msg": @[msg]
                            }];
                        }
                    }
                }
                [self clearRes];
                break;
            case AgoraChatCallState_Outgoing: {
                [self refreshUIOutgoing];
                AgoraChatCallType callType = self.modal.currentCall.callType;
                BOOL speakOut = callType == AgoraChatCallType1v1Video || AgoraChatCallTypeMultiVideo;
                [self speakeOut: speakOut];
                break;
            }
            case AgoraChatCallState_Alerting: {
                [self refreshUIAlerting];
                AgoraChatCallType callType = self.modal.currentCall.callType;
                BOOL speakOut = callType == AgoraChatCallType1v1Video || AgoraChatCallTypeMultiVideo;
                [self speakeOut: speakOut];
                break;
            }
            case AgoraChatCallState_Answering:
                [self refreshUIAnswering];
                break;
            case AgoraChatCallState_Unanswered:
                if (self.modal.state == AgoraChatCallState_Unanswered && (self.modal.currentCall.callType == AgoraChatCallType1v1Audio || self.modal.currentCall.callType == AgoraChatCallType1v1Video)) {
                    [self clearResWithViewController:NO];
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
            if (msg.chatType == AgoraChatTypeChat) {
                [weakself _parseMsg:msg];
            }
        }
    });
}

- (void)cmdMessagesDidReceive:(NSArray *)aCmdMessages
{
    __weak typeof(self) weakself = self;
    dispatch_async(weakself.workQueue, ^{
        for (AgoraChatMessage *msg in aCmdMessages) {
            if (msg.chatType == AgoraChatTypeChat) {
                [weakself _parseMsg:msg];
            }
        }
    });
}

#pragma mark - sendMessage

//发送呼叫邀请消息
- (void)sendInviteMsgToCallee:(NSString*)aUid isGroup:(BOOL)isGroup type:(AgoraChatCallType)aType callId:(NSString*)aCallId channelName:(NSString*)aChannelName ext:(NSDictionary*)aExt completion:(void (^)(NSString* callId,AgoraChatCallError*))aCompletionBlock
{
    if (aUid.length == 0 || aCallId.length == 0 || aChannelName.length == 0) {
        return;
    }
    
    if (!isGroup && [aUid isEqualToString:AgoraChatClient.sharedClient.currentUsername]) {
        return;
    }
    
    AgoraChatType chatType = isGroup ? AgoraChatTypeGroupChat : AgoraChatTypeChat;
    AgoraChatMessageBody *msgBody;
//    if (aType == AgoraChatCallType1v1Video || aType == AgoraChatCallType1v1Audio || isGroup) {
        NSString *strType = AgoraChatCallLocalizableString(@"StartAudioCall", nil);
//        if (aType == AgoraChatCallTypeMultiVideo || aType == AgoraChatCallType1v1Video) {
//            strType = AgoraChatCallLocalizableString(@"StartVideoCall", nil);
//        }
        msgBody = [[AgoraChatTextMessageBody alloc] initWithText:strType];
//    } else {
//        msgBody = [[AgoraChatCmdMessageBody alloc] initWithAction:@"rtcCall"];
//    }
    
    NSMutableDictionary *ext = [@{
        kMsgType:kMsgTypeValue,
        kAction:kInviteAction,
        kCallId:aCallId,
        kCallType:@(aType),
        kCallerDevId:self.modal.curDevId,
        kChannelName:aChannelName,
        kTs:[self getTs],
    } mutableCopy];
    if (aExt && aExt.count > 0) {
        [ext setValue:aExt forKey:kExt];
    }
    if (!isGroup) {
        ext[@"em_push_ext"] = @{
            @"type": @"call",
            @"custom": @{
                @"callId": aCallId,
            }
        };
        ext[@"em_apns_ext"] = @{
            @"em_push_type": @"voip",
        };
    }
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:AgoraChatClient.sharedClient.currentUsername to:aUid body:msgBody ext:ext];
    msg.chatType = chatType;
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
- (void)sendAlertMsgToCaller:(NSString *)aCallerUid callId:(NSString *)aCallId devId:(NSString *)aDevId
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
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aCallerUid from:AgoraChatClient.sharedClient.currentUsername to:aCallerUid body:msgBody ext:ext];
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
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:AgoraChatClient.sharedClient.currentUsername to:aUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (error) {
            [weakself callBackError:AgoarChatCallErrorTypeIM code:error.code description:error.errorDescription];
        }
    }];
}

// 发送取消呼叫消息
- (void)sendCancelCallMsgToCallee:(NSString *)aUid callId:(NSString *)aCallId
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
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:AgoraChatClient.sharedClient.currentUsername to:aUid body:msgBody ext:ext];
    __weak typeof(self) weakself = self;
    [AgoraChatClient.sharedClient.chatManager sendMessage:msg progress:nil completion:^(AgoraChatMessage *message, AgoraChatError *error) {
        if (error) {
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
    if (self.modal.currentCall.callType == AgoraChatCallType1v1Audio && self.bNeedSwitchToVoice) {
        [ext setObject:@YES forKey:kVideoToVoice];
    }
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aCallerUid from:AgoraChatClient.sharedClient.currentUsername to:aCallerUid body:msgBody ext:ext];
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
        kCalleeDevId:aDevId,
        kCallResult:aResult,
        kTs:[self getTs]
    };
    AgoraChatMessage *msg = [[AgoraChatMessage alloc] initWithConversationID:aUid from:AgoraChatClient.sharedClient.currentUsername to:aUid body:msgBody ext:ext];
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
        [weakself _stopConfirmTimer:callId];
        [weakself _stopAlertTimer:callId];
        [weakself callBackCallEnd:AgoraChatCallEndReasonRemoteCancel];
        weakself.modal.state = AgoraChatCallState_Idle;
        [weakself stopSound];
    };
    void (^parseAnswerMsgExt)(NSDictionary *) = ^void (NSDictionary *ext) {
        //[[EMClient sharedClient] log:[NSString stringWithFormat:@"parseAnswerMsgExt currentCallId:%@,state:%ld",weakself.modal.currentCall.callId,weakself.modal.state]];
        if (weakself.modal.currentCall && [weakself.modal.currentCall.callId isEqualToString:callId] && [weakself.modal.curDevId isEqualToString:callerDevId]) {
            if (weakself.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || weakself.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
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
                            [weakself callBackCallEnd:AgoraChatCallEndReasonRemoteRefuse];
                            weakself.modal.state = AgoraChatCallState_Unanswered;
                        } else if ([result isEqualToString:kBusyResult]) {
                            [weakself callBackCallEnd:AgoraChatCallEndReasonBusy];
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
                    AgoraChatCallKitModel *model = [self getUnhandleCall];
                    if (model.handleType == AgoraChatCallKitModelHandleTypeAccept) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self acceptAction];
                        });
                    } else if (model.handleType == AgoraChatCallKitModelHandleTypeRefuse) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self hangupAction];
                        });
                    }
                    [self clearUnhandleCall];
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
                        if (weakself.modal.currentCall.callType != AgoraChatCallType1v1Audio && weakself.modal.currentCall.callType != AgoraChatCallTypeMultiAudio) {
                            [weakself.callVC setupLocalVideo];
                        }
                        [weakself fetchToken];
                    });
                }
            } else {
                // 已在其他端处理
                if ([result isEqualToString:kAcceptResult]) {
                    [weakself callBackCallEnd:AgoraChatCallEndReasonAnswerOtherDevice];
                } else {
                    [weakself callBackCallEnd:AgoraChatCallEndReasonRefuseOtherDevice];
                }
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
        [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_startCallTimer,user:%@",aRemoteUser]];
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
            [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"stopCallTimer:%@",aRemoteUser]];
            [tm invalidate];
            [weakself.callTimerDic removeObjectForKey:aRemoteUser];
        }
    });
}

- (void)_timeoutCall:(NSTimer*)timer
{
    NSString *aRemoteUser = (NSString*)[timer userInfo];
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_timeoutCall,user:%@",aRemoteUser]];
    [self.callTimerDic removeObjectForKey:aRemoteUser];
    [self sendCancelCallMsgToCallee:aRemoteUser callId:self.modal.currentCall.callId];
    if (self.modal.currentCall.callType != AgoraChatCallTypeMultiVideo && self.modal.currentCall.callType != AgoraChatCallTypeMultiAudio) {
        [self callBackCallEnd:AgoraChatCallEndReasonNoResponse];
        self.modal.state = AgoraChatCallState_Unanswered;
    } else {
        __weak typeof(self) weakself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [[weakself getMultiVC] removePlaceHolderForMember:aRemoteUser];
        });
    }
}

- (void)_startAlertTimer:(NSString*)callId
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_startAlertTimer,callId:%@",callId]];
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *tm = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(_timeoutAlert:) userInfo:callId repeats:NO];
        [weakself.alertTimerDic setObject:tm forKey:callId];
    });
}

- (void)_stopAlertTimer:(NSString*)callId
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_stopAlertTimer,callId:%@",callId]];
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
    [AgoraChatClient.sharedClient log:@"_stopAllAlertTimer"];
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
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_timeoutAlert,callId:%@",callId]];
    [self.alertTimerDic removeObjectForKey:callId];
}

- (void)_startConfirmTimer:(NSString*)callId
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(weakself.confirmTimer) {
            [weakself.confirmTimer invalidate];
        }
        weakself.confirmTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(_timeoutConfirm:) userInfo:callId repeats:NO];
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
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_timeoutConfirm,callId:%@",callId]];
    if (self.modal.currentCall && [self.modal.currentCall.callId isEqualToString:callId]) {
        [self callBackCallEnd:AgoraChatCallEndReasonNoResponse];
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
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"_timeoutConfirm,callId:%@",callId]];
    [self stopSound];
    if (self.modal.currentCall && [self.modal.currentCall.callId isEqualToString:callId]) {
        [self callBackCallEnd:AgoraChatCallEndReasonNoResponse];
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
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"rtcEngine didOccurError:%ld",(long)errorCode]];
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
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"join channel success!!! channel:%@,uid:%lu",channel,(unsigned long)uid]];
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
    if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
        [[self getMultiVC] removeRemoteViewForUser:@(uid)];
        [self.modal.currentCall.allUserAccounts removeObjectForKey:@(uid)];
    } else {
        [self callBackCallEnd:AgoraChatCallEndReasonHangup];
        self.modal.state = AgoraChatCallState_Idle;
    }
}

// 对方加入频道
- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"didJoinedOfUid:%lu",(unsigned long)uid]];
    if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
        NSString *username = [self.modal.currentCall.allUserAccounts objectForKey:@(uid)];
        [[self getMultiVC] addMember:@(uid) username:username enableVideo:self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo];
        if (username.length > 0) {
            [self _stopCallTimer:username];
            [[self getMultiVC] removePlaceHolderForMember:username];
        }
    } else {
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
    if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo) {
        [[self getMultiVC] setRemoteEnableVideo:!muted uId:@(uid)];
    } else if (self.modal.currentCall.callType == AgoraChatCallType1v1Video) {
        [[self getSingleVC] setRemoteEnableVideo:!muted];
    }
}

// 对方打开/关闭音频
- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid
{
    AVAudioSession.sharedInstance;
    
    if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
        [[self getMultiVC] setRemoteMute:muted uid:@(uid)];
    } else {
        [[self getSingleVC] setRemoteMute:muted];
    }
}

// 对方发视频流
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed
{
    if (self.modal.currentCall.callType == AgoraChatCallType1v1Video) {
        [[self getSingleVC] setRemoteEnableVideo:YES];
    }
    [self.callVC setupRemoteVideoView:uid size:size];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteAudioFrameOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"firstRemoteAudioFrameOfUid:%lu",(unsigned long)uid]];
}

- (void)rtcEngine:(AgoraRtcEngineKit * _Nonnull)engine remoteVideoStateChangedOfUid:(NSUInteger)uid state:(AgoraVideoRemoteState)state reason:(AgoraVideoRemoteReason)reason elapsed:(NSInteger)elapsed
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"remoteVideoStateChangedOfUid uid:%d staate:%d,reason:%d", uid, state,reason]];
//    if (reason == AgoraVideoRemoteStateReasonRemoteMuted && self.modal.currentCall.callType == AgoraChatCallType1v1Video) {
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
    if (self.modal.currentCall && (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio)) {
        for (AgoraRtcAudioVolumeInfo *speakerInfo in speakers) {
            if (speakerInfo.volume > 5) {
                [[self getMultiVC] setUser:speakerInfo.uid isTalking:YES];
            }
        }
    }
}

#pragma mark - 提供delegate

- (void)callBackCallEnd:(AgoraChatCallEndReason)reason
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reportCallEnd:self.modal.currentCall reason:reason];
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
            [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"Warning: You have not implement interface callDidRequestRTCTokenForAppId:channelName:account:!!!!"]];
        }
    } else {
        [self setRTCToken:nil channelName:self.modal.currentCall.channelName uid:arc4random()];
    }
}

@end


@implementation AgoraChatCallManager (Private)

- (void)hangupAction
{
    [AgoraChatClient.sharedClient log:[NSString stringWithFormat:@"hangupAction,curState:%ld", (long)self.modal.state]];
    if (self.modal.state == AgoraChatCallState_Answering) {
        // 正常挂断
        if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
            if (self.callTimerDic.count > 0) {
                NSArray *tmArray = [self.callTimerDic allValues];
                for (NSTimer *tm in tmArray) {
                    [tm fire];
                }
                [self.callTimerDic removeAllObjects];
            }
        }
        [self callBackCallEnd:AgoraChatCallEndReasonHangup];
    } else if (self.modal.state == AgoraChatCallState_Outgoing) {
        // 取消呼叫
        [self _stopCallTimer:self.modal.currentCall.remoteUserAccount];
        [self sendCancelCallMsgToCallee:self.modal.currentCall.remoteUserAccount callId:self.modal.currentCall.callId];
        [self callBackCallEnd:AgoraChatCallEndReasonCancel];
    } else if (self.modal.state == AgoraChatCallState_Alerting) {
        // 拒绝
        [self stopSound];
        [self sendAnswerMsg:self.modal.currentCall.remoteUserAccount callId:self.modal.currentCall.callId result:kRefuseresult devId:self.modal.currentCall.remoteCallDevId];
        [self callBackCallEnd:AgoraChatCallEndReasonRefuse];
    }
    self.modal.state = AgoraChatCallState_Idle;
}

- (void)acceptAction
{
    if (self.config.enableIosCallKit) {
        if (!self.callVC) {
            if (self.modal.currentCall.callType == AgoraChatCallTypeMultiVideo || self.modal.currentCall.callType == AgoraChatCallTypeMultiAudio) {
                self.callVC = [[AgoraChatCallMultiViewController alloc] initWithCallType:self.modal.currentCall.callType];
            } else {
                self.callVC = [[AgoraChatCallSingleViewController alloc] initWithisCaller:self.modal.currentCall.isCaller type:self.modal.currentCall.callType remoteName:self.modal.currentCall.remoteUserAccount];
                ((AgoraChatCallSingleViewController *)self.callVC).remoteUserAccount = self.modal.currentCall.remoteUserAccount;
            }
            self.callVC.callType = self.modal.currentCall.callType;
            self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
            [UIWindow.agoraChatCallKit_keyWindow.rootViewController presentViewController:self.callVC animated:YES completion:nil];
        }
    } else {
        [self stopSound];
    }
    
    [self sendAnswerMsg:self.modal.currentCall.remoteUserAccount callId:self.modal.currentCall.callId result:kAcceptResult devId:self.modal.currentCall.remoteCallDevId];
}

- (BOOL)checkCallIdCanHandle:(NSString *)callId
{
    return [self.modal.currentCall.callId isEqualToString:callId];
}

- (void)switchCameraAction
{
    [self.agoraKit switchCamera];
}

- (void)inviteAction
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(multiCallDidInvitingWithCurVC:callType:excludeUsers:ext:)]){
        NSMutableArray *array = [NSMutableArray array];
        [array addObject:AgoraChatClient.sharedClient.currentUsername];
        [array addObjectsFromArray:[self getJoinedUsernameList]];
        NSArray *invitingMems = [self.callTimerDic allKeys];
        [array addObjectsFromArray:invitingMems];
        [self.delegate multiCallDidInvitingWithCurVC:self.callVC callType:self.modal.currentCall.callType excludeUsers:array ext:self.modal.currentCall.ext];
    }
}

- (void)muteAudio:(BOOL)muted
{
    [self.agoraKit muteLocalAudioStream:muted];
    [self.callVC didMuteAudio:muted];
}

- (void)speakeOut:(BOOL)enable
{
    [self.agoraKit setEnableSpeakerphone:enable];
    [self.callVC didSpeakeOut:enable];
}

- (BOOL)speakeOut
{
    return [self.agoraKit isSpeakerphoneEnabled];
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
    canvas.renderMode = AgoraVideoRenderModeHidden;
    canvas.view = view;
    [self.agoraKit setupRemoteVideo:canvas];
}

- (void)startPreview
{
    [self.agoraKit startPreview];
}

- (void)setupLocalVideo:(UIView *)displayView
{
    if (displayView) {
        [self.agoraKit setVideoEncoderConfiguration:self.config.encoderConfiguration];
        AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
        canvas.uid = 0;
        canvas.renderMode = AgoraVideoRenderModeHidden;
        canvas.view = displayView;
        [self.agoraKit setupLocalVideo:canvas];
        [self.agoraKit enableVideo];
        [self.agoraKit startPreview];
    } else {
        [self.agoraKit stopPreview];
    }
}

- (void)joinChannel
{
    __weak typeof(self) weakself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (weakself.modal.hasJoinedChannel) {
            [weakself.agoraKit leaveChannel:nil];
        }
        [weakself.agoraKit joinChannelByToken:weakself.modal.agoraRTCToken channelId:weakself.modal.currentCall.channelName info:@"" uid:self.modal.agoraUid joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
            [AgoraChatClient.sharedClient log:@"join success"];
            if ([weakself.delegate respondsToSelector:@selector(callDidJoinChannel:uid:)]) {
                [weakself.delegate callDidJoinChannel:channel uid:uid];
            }
            weakself.modal.hasJoinedChannel = YES;
            [weakself.modal.currentCall.allUserAccounts setObject:AgoraChatClient.sharedClient.currentUsername forKey:@(uid)];
        }];
    });
}

- (void)joinToMutleCall:(AgoraChatMessage *)callMessage
{
    NSDictionary *ext = callMessage.ext;
    NSString *from = callMessage.from;
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
    
    if (self.modal.currentCall && [self.modal.currentCall.callId isEqualToString:callId]) {
        return;
    }
    if ([self.alertTimerDic objectForKey:callId]) {
        return;
    }
    if ([self isBusy]) {
        return;
    }
    AgoraChatCall *call = [[AgoraChatCall alloc] init];
    call.callId = callId;
    call.isCaller = NO;
    call.callType = (AgoraChatCallType)[callType intValue];
    call.remoteCallDevId = callerDevId;
    call.channelName = channelname;
    call.remoteUserAccount = from;
    call.ext = callExt;
    self.modal.currentCall = call;
    
    self.callVC = [[AgoraChatCallMultiViewController alloc] initWithCallType:self.modal.currentCall.callType];
    self.callVC.callType = self.modal.currentCall.callType;
    self.callVC.modalPresentationStyle = UIModalPresentationFullScreen;
    UIWindow *keyWindow = UIWindow.agoraChatCallKit_keyWindow;
    if (!keyWindow) {
        return;
    }
    UIViewController *rootVC = keyWindow.rootViewController;
    [rootVC presentViewController:self.callVC animated:NO completion:^{
        self.modal.state = AgoraChatCallState_Answering;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.modal.currentCall.callType != AgoraChatCallType1v1Audio && self.modal.currentCall.callType != AgoraChatCallTypeMultiAudio) {
                [self.callVC setupLocalVideo];
            }
            [self fetchToken];
        });
    }];
}

@end
