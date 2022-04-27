//
//  EaseCallStreamViewModel.m
//  AgoraChatCallKit
//
//  Created by 冯钊 on 2022/4/20.
//

#import "EaseCallStreamViewModel.h"

@implementation EaseCallStreamViewModel

- (instancetype)init
{
    if (self = [super init]) {
        _enableVoice = YES;
        _isTalking = NO;
    }
    return self;
}

- (void)setCallType:(EaseCallType)callType
{
    _callType = callType;
}

- (void)setEnableVideo:(BOOL)enableVideo {
    _enableVideo = enableVideo;
}

@end
