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
}

- (void)reportNewIncomingCall:(AgoraChatCall *)call
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:call.remoteUserAccount];
    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = handle;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    update.hasVideo = call.callType == AgoraChatCallType1v1Video || call.callType == AgoraChatCallTypeMultiVideo;
    update.localizedCallerName = call.remoteUserAccount;
    if (call.callUUID) {
        [self.provider reportNewIncomingCallWithUUID:call.callUUID update:update completion:^(NSError * _Nullable error) {
            NSLog(@"%@", error);
        }];
    } else {
    
        [self clearRes];
    }
}

- (void)reportCallEnd:(AgoraChatCall *)call reason:(AgoarChatCallEndReason)reason
{
    if (![self getAgoraChatCallConfig].enableIosCallKit) {
        return;
    }
    CXCallEndedReason callKitReason;
    switch (reason) {
        case AgoarChatCallEndReasonHangup:
            callKitReason = CXCallEndedReasonRemoteEnded;
            break;
        case AgoarChatCallEndReasonCancel:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
        case AgoarChatCallEndReasonRemoteCancel:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
        case AgoarChatCallEndReasonRefuse:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
        case AgoarChatCallEndReasonRemoteRefuse:
            callKitReason = CXCallEndedReasonUnanswered;
            break;
        case AgoarChatCallEndReasonBusy:
            callKitReason = CXCallEndedReasonUnanswered;
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
    
    if (call.callUUID) {
        [self.provider reportCallWithUUID:call.callUUID endedAtDate:[NSDate date] reason:callKitReason];
    }
}

- (void)providerDidReset:(CXProvider *)provider
{
    
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action
{
    [self acceptAction];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action
{
    [self hangupAction];
    [action fulfill];
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action
{
    [self muteAudio:action.muted];
    [action fulfill];
}

//- (void)provider:(CXProvider *)provider performSetHeldCallAction:(CXSetHeldCallAction *)action
//{
//    [self speakeOut:action.onHold];
//    [action fulfill];
//}

@end
