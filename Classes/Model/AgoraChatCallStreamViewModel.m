//
//  EaseCallStreamViewModel.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/20.
//

#import "AgoraChatCallStreamViewModel.h"

@implementation AgoraChatCallStreamViewModel

- (instancetype)init
{
    if (self = [super init]) {
        _enableVoice = YES;
        _isTalking = NO;
    }
    return self;
}

- (void)setCallType:(AgoraChatCallType)callType
{
    _callType = callType;
}

- (void)setEnableVideo:(BOOL)enableVideo {
    _enableVideo = enableVideo;
}

- (void)setJoined:(BOOL)joined {
    _joined = joined;
}

@end
