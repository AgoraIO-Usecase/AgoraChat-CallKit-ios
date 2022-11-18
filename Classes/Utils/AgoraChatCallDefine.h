//
//  AgoraChatCallDefine.h
//  EaseIM
//
//  Created by lixiaoming on 2021/1/8.
//  Copyright © 2021 lixiaoming. All rights reserved.
//

#ifndef AgoraChatCallDefine_h
#define AgoraChatCallDefine_h
/**
 *  \~chinese
 * 通话类型枚举类。
 *
 *  \~english
 * The call types.
 */
typedef NS_ENUM(NSInteger,AgoraChatCallType) {
    AgoraChatCallType1v1Audio,    /** \~chinese 一对一语音通话。  \~english The one-to-one voice call. */
    AgoraChatCallType1v1Video,    /** \~chinese 一对一视频通话。  \~english The one-to-one video call. */
    AgoraChatCallTypeMultiVideo,  /** \~chinese 多人音频通话。  \~english The multi-party voice call. */
    AgoraChatCallTypeMultiAudio,  /** \~chinese 多人视频通话。  \~english The multi-party video call. */
};

/**
 *  \~chinese
 * 通话结束原因枚举类。
 *
 *  \~english
 * The reasons why the call ends.
 */
typedef NS_ENUM(NSInteger,AgoraChatCallEndReason) {
    AgoraChatCallEndReasonHangup,               /** \~chinese 通话中挂断。 \~english The caller or callee hungs up to end the call. */
    AgoraChatCallEndReasonCancel,               /** \~chinese 主叫取消通话。 \~english The caller cancels the call. */
    AgoraChatCallEndReasonRemoteCancel,         /** \~chinese 主叫取消通话。 \~english The caller cancels the call. */
    AgoraChatCallEndReasonRefuse,
    AgoraChatCallEndReasonRemoteRefuse,         /** \~chinese 被叫拒接。  \~english The callee refuses to answer the call. */
    AgoraChatCallEndReasonBusy,                 /** \~chinese 被叫忙线中。  \~english The callee is busy. */
    AgoraChatCallEndReasonNoResponse,           /** \~chinese 被叫未接听。  \~english The callee misses the call.*/
    AgoraChatCallEndReasonAnswerOtherDevice,    /** \~chinese 该通话已在其他设备处理。  \~english The call is handled on another device.*/
    AgoraChatCallEndReasonRefuseOtherDevice,    /** \~chinese 该通话已在其他设备处理。  \~english The call is handled on another device.*/
};

/**
 *  \~chinese
 * 错误类型枚举类。
 *
 *  \~english
 * The error types.
 */
typedef NS_ENUM(NSInteger,AgoarChatCallErrorType) {
    AgoarChatCallErrorTypeProcess,  /** \~chinese 业务处理异常。  \~english  The business logic error. */
    AgoarChatCallErrorTypeRTC,      /** \~chinese RTC 异常，声网接口返回。  \~english The RTC error, which is returned by an API of Agora. */
    AgoarChatCallErrorTypeIM        /** \~chinese Chat 异常，Chat SDK 返回。 \~english The Chat error, which is returned by the Chat SDK. */
};

/**
 *  \~chinese
 * 业务逻辑异常枚举类。
 *
 *  \~english
 * The business logic errors.
 */
typedef NS_ENUM(NSInteger,AgoraChatCallProcessErrorCode) {
    AgoraChatCallProcessErrorCodeInvalidParams = 100,   /** \~chinese 参数错误。  \~english  The parameter error. */
    AgoraChatCallProcessErrorCodeBusy,                  /** \~chinese 当前用户处于忙碌状态。  \~english  The current user is busy. */
    AgoraChatCallProcessErrorCodeFetchTokenFail,        /** \~chinese token 错误。  \~english  The token is invalid. */
};

#endif /* AgoraChatCallDefine_h */
