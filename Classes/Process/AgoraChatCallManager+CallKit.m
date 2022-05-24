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

- (void)reportNewIncomingCall:(AgoraChatCall *)call
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    if (self.callKitCurrentCallReportNewIncoming) {
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
    if (self.callKitCurrentCallUUID) {
        [self.provider reportCallWithUUID:self.callKitCurrentCallUUID endedAtDate:nil reason:CXCallEndedReasonUnanswered];
    }
    
    self.callKitCurrentCallUUID = [NSUUID UUID];
    [self.provider reportNewIncomingCallWithUUID:self.callKitCurrentCallUUID update:update completion:^(NSError * _Nullable error) {
        NSLog(@"%@", error);
    }];
}

- (void)reportCallEnd:(AgoraChatCall *)call reason:(AgoarChatCallEndReason)reason
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    if (!self.callKitCurrentCallUUID) {
        return;
    }
    CXCallEndedReason callKitReason;
    switch (reason) {
        case AgoarChatCallEndReasonHangup:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonCancel:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonRemoteCancel:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonRefuse:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonRemoteRefuse:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonBusy:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonNoResponse:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
        case AgoarChatCallEndReasonRemoteNoResponse:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
        case AgoarChatCallEndReasonHandleOnOtherDevice:
            callKitReason = CXCallEndedReasonAnsweredElsewhere;
            break;
        default:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
    }
    
    [self.provider reportCallWithUUID:self.callKitCurrentCallUUID endedAtDate:nil reason:callKitReason];
    self.callKitCurrentCallUUID = nil;
    self.callKitCurrentCallReportNewIncoming = NO;
}

- (void)providerDidReset:(CXProvider *)provider
{
    
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
    if ([self.callKitCurrentCallUUID isEqual:action.callUUID]) {
        [self acceptAction];
    }
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
    if ([self.callKitCurrentCallUUID isEqual:action.callUUID]) {
        [self hangupAction];
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

@end
