//
//  AgoraChatCallManager+CallKit.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/5/11.
//

#import "AgoraChatCallManager+CallKit.h"
#import "AgoraChatCallModal.h"
#import "AgoraChatCallManager+Private.h"
#import "UIImage+Ext.h"

@import CallKit;
@import AgoraChat;

static NSUUID *callKitCurrentCallUUID;
static NSString *pushKitRecvCallId;
static AgoraChatCallKitModel *callKitModel;

@implementation AgoraChatCallManager (CallKit)

- (void)initCallKit
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    CXProviderConfiguration *config = [[CXProviderConfiguration alloc] initWithLocalizedName:@"AgoraChatCallManager"];
    config.supportsVideo = YES;
    config.maximumCallGroups = 1;
    config.maximumCallsPerCallGroup = 1;
    config.iconTemplateImageData = UIImagePNGRepresentation([UIImage agoraChatCallKit_imageNamed:@"callkit_icon"]);
    if (@available(iOS 11.0, *)) {
        config.includesCallsInRecents = NO;
    }
    self.provider = [[CXProvider alloc] initWithConfiguration:config];
    [self.provider setDelegate:self queue:dispatch_get_main_queue()];
    
    self.callController = [[CXCallController alloc] initWithQueue:dispatch_get_main_queue()];
}

- (void)requestPushKitToken
{
    PKPushRegistry *pushKit = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushKit.delegate = self;
    pushKit.desiredPushTypes = [NSSet setWithObjects:PKPushTypeVoIP, nil];
}

- (void)didRecvCancelMessage:(NSString *)callId
{
    if ([callId isEqualToString:pushKitRecvCallId]) {
        [self reportCallEndWithReason:CXCallEndedReasonUnanswered];
    }
}

- (void)reportNewIncomingCall:(AgoraChatCall *)call
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    if (pushKitRecvCallId) {
        return;
    }
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:call.remoteUserAccount];
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = handle;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    update.hasVideo = NO;
    update.localizedCallerName = call.remoteUserAccount;
    if (callKitCurrentCallUUID) {
        [self.provider reportCallWithUUID:callKitCurrentCallUUID endedAtDate:nil reason:CXCallEndedReasonUnanswered];
    }
    
    callKitCurrentCallUUID = [NSUUID UUID];
    [self.provider reportNewIncomingCallWithUUID:callKitCurrentCallUUID update:update completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)reportCallEnd:(AgoraChatCall *)call reason:(AgoarChatCallEndReason)reason
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    if (!callKitCurrentCallUUID) {
        return;
    }
    CXCallEndedReason callKitReason;
    switch (reason) {
        case AgoarChatCallEndReasonHangup:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonAnswerOtherDevice:
            callKitReason = CXCallEndedReasonAnsweredElsewhere;
            break;
        case AgoarChatCallEndReasonRefuseOtherDevice:
            callKitReason = CXCallEndedReasonAnsweredElsewhere;
            break;
        default:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
    }
    [self reportCallEndWithReason:callKitReason];
}

- (void)reportCallEndWithReason:(CXCallEndedReason)reason
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    if (!callKitCurrentCallUUID) {
        return;
    }
    
    [self.provider reportCallWithUUID:callKitCurrentCallUUID endedAtDate:nil reason:reason];
    callKitCurrentCallUUID = nil;
    pushKitRecvCallId = nil;
}

- (void)providerDidReset:(CXProvider *)provider
{
    
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
    if ([callKitCurrentCallUUID isEqual:action.callUUID]) {
        if (callKitModel && ![self checkCallIdCanHandle:callKitModel.unhandleCallId]) {
            callKitModel.handleType = AgoraChatCallKitModelHandleTypeAccept;
        } else {
            [self acceptAction];
        }
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
    if ([callKitCurrentCallUUID isEqual:action.callUUID]) {
        if (callKitModel && ![self checkCallIdCanHandle:callKitModel.unhandleCallId]) {
            callKitModel.handleType = AgoraChatCallKitModelHandleTypeRefuse;
        } else {
            [self hangupAction];
        }
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action
{
//    action.muted = NO;
//    [self muteAudio:action.muted];
    [action fulfill];
}

//- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action
//{
//    [self speakeOut:action.onHold];
//    [action fulfill];
//}

#pragma mark - PKPushRegistryDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)pushCredentials forType:(PKPushType)type
{
    [AgoraChatClient.sharedClient registerPushKitToken:pushCredentials.token completion:^(AgoraChatError *aError) {
        if (aError) {
            NSLog(@"AgoraChatClient registerPushKitToken error: %@", aError.description);
        }
    }];
}

- (void)pushRegistry:(PKPushRegistry *)registry didInvalidatePushTokenForType:(PKPushType)type
{
    NSLog(@"PushKit %s type=%d", __FUNCTION__, type);
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion
{
    NSString *from = payload.dictionaryPayload[@"f"];
    NSDictionary *custom = payload.dictionaryPayload[@"e"];
    NSString *callId = custom[@"callId"];
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:from];
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = handle;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    update.hasVideo = NO;
    update.localizedCallerName = from;
    
    pushKitRecvCallId = callId;
    callKitModel = [[AgoraChatCallKitModel alloc] init];
    callKitModel.unhandleCallId = callId;
    callKitModel.handleType = AgoraChatCallKitModelHandleTypeUnhandle;
    __weak typeof(self)weakSelf = self;
    callKitModel.timeoutBlock = dispatch_block_create(0, ^{
        [weakSelf reportCallEndWithReason:CXCallEndedReasonUnanswered];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), callKitModel.timeoutBlock);
    
    callKitCurrentCallUUID = NSUUID.UUID;
    [self.provider reportNewIncomingCallWithUUID:callKitCurrentCallUUID update:update completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
    completion();
}

- (AgoraChatCallKitModel *)getUnhandleCall
{
    if (callKitModel && callKitModel.handleType != AgoraChatCallKitModelHandleTypeUnhandle) {
        return callKitModel;
    }
    [self clearUnhandleCall];
    return nil;
}

- (void)clearUnhandleCall
{
    if (callKitModel.timeoutBlock) {
        dispatch_block_cancel(callKitModel.timeoutBlock);
        callKitModel.timeoutBlock = nil;
    }
    callKitModel = nil;
}

@end
