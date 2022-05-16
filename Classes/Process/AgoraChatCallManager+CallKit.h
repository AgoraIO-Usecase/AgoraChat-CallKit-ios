//
//  AgoraChatCallManager+CallKit.h
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/5/11.
//

#import "AgoraChatCallManager.h"

@class AgoraChatCall;

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallManager (CallKit) <CXProviderDelegate>

- (void)initCallKit;

- (void)reportNewIncomingCall:(AgoraChatCall *)call;
- (void)reportCallEnd:(AgoraChatCall *)call reason:(AgoarChatCallEndReason)reason;

@end

NS_ASSUME_NONNULL_END
