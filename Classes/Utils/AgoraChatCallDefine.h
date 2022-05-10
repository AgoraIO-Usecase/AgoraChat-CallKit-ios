//
//  AgoraChatCallDefine.h
//  EaseIM
//
//  Created by lixiaoming on 2021/1/8.
//  Copyright © 2021 lixiaoming. All rights reserved.
//

#ifndef AgoraChatCallDefine_h
#define AgoraChatCallDefine_h
// 通话类型
typedef NS_ENUM(NSInteger,AgoraChatCallType) {
    EaseCallType1v1Audio,       // 1v1语音
    EaseCallType1v1Video,       // 1v1视频
    EaseCallTypeMultiVideo,     // 多人视频通话
    EaseCallTypeMultiAudio,     // 多人语音通话
};

//通话结束原因
typedef NS_ENUM(NSInteger,AgoarChatCallEndReason) {
    AgoarChatCallEndReasonHangup,// 挂断通话
    AgoarChatCallEndReasonCancel,// 取消呼叫
    AgoarChatCallEndReasonRemoteCancel,// 对方取消呼叫
    AgoarChatCallEndReasonRefuse,// 对方拒绝呼叫
    AgoarChatCallEndReasonBusy,// 忙碌
    AgoarChatCallEndReasonNoResponse,// 无响应
    AgoarChatCallEndReasonRemoteNoResponse,// 对方无响应
    AgoarChatCallEndReasonHandleOnOtherDevice// 已在其他设备处理
};

// 错误类型
typedef NS_ENUM(NSInteger,AgoarChatCallErrorType) {
    AgoarChatCallErrorTypeProcess,// 业务处理异常
    AgoarChatCallErrorTypeRTC, // RTC异常，声网接口返回
    AgoarChatCallErrorTypeIM // IM异常，环信SDK接口返回
};

// 业务逻辑异常代码
typedef NS_ENUM(NSInteger,AgoraChatCallProcessErrorCode) {
    AgoraChatCallProcessErrorCodeInvalidParams = 100, // 参数错误
    AgoraChatCallProcessErrorCodeBusy, //当前处于忙碌状态
    AgoraChatCallProcessErrorCodeFetchTokenFail, //token错误

};

#endif /* AgoraChatCallDefine_h */
