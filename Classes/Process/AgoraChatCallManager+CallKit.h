//
//  AgoraChatCallManager+CallKit.h
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/5/11.
//

#import "AgoraChatCallManager.h"
#import "AgoraChatCallKitModel.h"

@import PushKit;
@class AgoraChatCall;

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallManager (CallKit) <CXProviderDelegate, PKPushRegistryDelegate>

- (void)initCallKit;
- (void)requestPushKitToken;
- (void)didRecvCancelMessage:(NSString *)callId;

- (void)reportNewIncomingCall:(AgoraChatCall *)call;
- (void)reportCallEnd:(AgoraChatCall *)call reason:(AgoarChatCallEndReason)reason;

- (AgoraChatCallKitModel *)getUnhandleCall;
- (void)clearUnhandleCall;

@end

NS_ASSUME_NONNULL_END
