//
//  EaseCallModal.h
//  EaseIM
//
//  Created by lixiaoming on 2021/1/8.
//  Copyright © 2021 lixiaoming. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AgoraChatCallDefine.h"
#import <AgoraRtcKit/AgoraRtcEngineKit.h>

/**
 *  \~chinese
 *  通话状态枚举类。
 *
 *  \~english
 *  The call state types.
 */
typedef NS_ENUM(NSInteger, AgoraChatCallState) {
    AgoraChatCallState_Idle,        // 空闲
    AgoraChatCallState_Outgoing,    // 呼叫中
    AgoraChatCallState_Alerting,    // 被呼叫
    AgoraChatCallState_Answering,   // 应答中
    AgoraChatCallState_Unanswered,  // 未应答
};

@protocol AgoraChatCallModalDelegate <NSObject>

/**
 *  \~chinese
 *  通话状态变更回调。
 *
 *  \~english
 *  Occurs when the call status changed.
 *
 */
- (void)callStateWillChangeTo:(AgoraChatCallState)newState from:(AgoraChatCallState)preState;

@end

NS_ASSUME_NONNULL_BEGIN

/**
 *  \~chinese
 *  通话数据模型。
 *
 *  \~english
 *  The call data model.
 *
 */
@interface AgoraChatCall : NSObject
/**
 *  \~chinese
 *  通话 ID，即通话的唯一标识。
 *
 *  \~english
 *  The call ID, which is the unique identifier of a call.
 */
@property (nonatomic,strong) NSString* callId;
/**
 *  \~chinese
 *  一对一通话的对端用户的 Chat  ID。
 *
 *  \~english
 *  The Chat user ID of the peer user of the one-to-one call.
 */
@property (nonatomic,strong) NSString* remoteUserAccount;
/**
 *  \~chinese
 *  一对一通话的对端用户的设备 ID。
 *
 *  主叫通过多端多设备登录时，被叫会收到的主叫发起呼叫的设备 ID，确保通话信令消息传输给相应设备处理。
 *
 *  \~english
 *  The device ID of the peer user of the one-to-one call.
 *
 *  If the caller is logged in to multiple devices, the callee will receive the ID of the device that the caller uses to make the call. This ensures that the call signaling messages are transmitted to the appropriate device for handling.
 */
@property (nonatomic,strong) NSString* remoteCallDevId;
/**
 *  \~chinese
 *  通话类型。
 *
 *  详见 {@link AgoraChatCallDefine::AgoraChatCallType}。
 *
 *  \~english
 *  The call type.
 *
 *  See {@link AgoraChatCallDefine::AgoraChatCallType}.
 */
@property (nonatomic) AgoraChatCallType callType;
/**
 *  \~chinese
 *  当前用户是否是主叫。
 *  - `YES`：是主叫。
 *  - `NO`：是被叫。
 *
 *  \~english
 *  Whether the current user is the caller.
 *  - `YES`: The current user is the caller.
 *  - `NO`: The current user is the callee.
 */
@property (nonatomic) BOOL isCaller;
/**
 *  \~chinese
 *  当前用户加入频道时使用的声网用户 ID。
 *
 *  \~english
 *  The Agora user ID that the current user uses to join the channel.
 */
@property (nonatomic) NSInteger uid;
/**
 *  \~chinese
 *  多人通话时，用户的声网用户 ID 与 Chat 用户 ID 的映射表。
 *
 *  该映射表的格式为 <声网用户 ID,Chat 用户 ID>。
 *
 *  即使用户离开会话，用户的信息仍存在于该映射表中。
 *
 *  \~english
 *  The table of mappings between Agora user IDs and Chat user IDs of users in a multi-party call.
 *
 *  This mapping table is in the format of <Agora user ID,Chat user ID>.
 *
 *  Even if a user leaves the call, the user information remains in this mapping table.
 *
 */
@property (nonatomic,strong) NSMutableDictionary<NSNumber*,NSString*>* allUserAccounts;
/**
 *  \~chinese
 *  当前通话的频道名称。
 *
 *  \~english
 *  The channel name of the current call.
 */
@property (nonatomic,strong) NSString* channelName;
/**
 *  \~chinese
 *  通话邀请中的扩展信息。
 *
 *  \~english
 *  The extension information in the call invitation.
 */
@property (nonatomic,strong) NSDictionary* ext;

@end

/**
 *  \~chinese
 *  当前通话状态的数据模型接口。
 *
 *  \~english
 *  The interface for the state data model of the ongoing call.
 */
@interface AgoraChatCallModal : NSObject
/**
 *  \~chinese
 *  当前通话的数据模型。
 *
 *  详见 {@link AgoraChatCall}。
 *
 *  \~english
 *  The data model of the ongoing call.
 *
 *  See {@link AgoraChatCall}.
 */
@property (nonatomic,strong) AgoraChatCall* __nullable currentCall;
/**
 *  \~chinese
 *  当前收到的通话请求。
 *
 *  \~english
 *  The current call request(s).
 */
@property (nonatomic,strong) NSMutableDictionary* recvCalls;
/**
 *  \~chinese
 *  本地设备 ID。
 *
 *  \~english
 *  The ID of the local device.
 */
@property (nonatomic,strong) NSString* curDevId;
/**
 *  \~chinese
 *  当前用户的 Chat 用户 ID。
 *
 *  \~english
 *  The Chat user ID of the current user.
 */
@property (nonatomic,strong) NSString* curUserAccount;
/**
 *  \~chinese
 *  当前用户加入频道时请求的 token。
 *
 *  \~english
 *  The token requested by the current user to join the channel.
 */
@property (nonatomic,strong) NSString* agoraRTCToken;
/**
 *  \~chinese
 *  通话状态。
 *
 *  详见 {@link AgoraChatCallState}。
 *
 *  \~english
 *  The call state.
 *
 *  See {@link AgoraChatCallState}.
 */
@property (nonatomic) AgoraChatCallState state;
/**
 *  \~chinese
 *  当前用户是否有加入的频道：
 *  - `YES`：有；
 *  - `NO`：没有。
 *
 *  \~english
 *  Whether the current user has joined a channel:
 *  - `YES`: The user has joined a channel.
 *  - `NO`: The user hasn't joined a channel yet.
 */
@property (nonatomic) BOOL hasJoinedChannel;
/**
 *  \~chinese
 *  当前用户的声网用户 ID。
 *
 *  \~english
 *  The Agora user ID of the current user.
 */
@property (nonatomic) NSInteger agoraUid;

- (instancetype)initWithDelegate:(id<AgoraChatCallModalDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
