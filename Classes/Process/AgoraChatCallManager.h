//
//  AgoraChatCallManager.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/18.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

@import Foundation;
@import CallKit;
#import "AgoraChatCallConfig.h"
#import "AgoraChatCallDefine.h"
#import "AgoraChatCallError.h"
@class AgoraChatMessage;

extern NSNotificationName const AGORA_CHAT_CALL_KIT_COMMMUNICATE_RECORD;

@protocol AgoraChatCallDelegate <NSObject>
/**
 * \~chinese
 * 通话结束回调。
 *
 * @param aChannelName  通话的频道名称，用于在声网水晶球查询通话质量。
 * @param aReason       通话结束原因。
 * @param aTm           通话时长，单位为秒。
 * @param aType         通话类型：
 *                      - `EaseCallTypeAudio`：一对一语音通话；
 *                      - `EaseCallTypeVideo`：一对一视频通话；
*                       - `EaseCallTypeMultiVoice`：多人音频通话；
 *                      - `EaseCallTypeMultiVideo`: 多人视频通话。
 *
 * \~english
 * Occurs when a call is ended.
 *
 * @param aChannelName  The channel name of the call. It is used for call quality queries on Agora Analytics.
 * @param aReason       The reason why the call is ended.
 * @param aTm           The call duration in seconds.
 * @param aType         The call type:
 *                      - `EaseCallTypeAudio`: The one-to-one voice call.
 *                      - `EaseCallTypeVideo`: The one-to-one video call.
 *                      - `EaseCallTypeMultiVoice`: The multi-party voice call.
 *                      - `EaseCallTypeMultiVideo`: The multi-party video call.
 */
- (void)callDidEnd:(NSString*_Nonnull)aChannelName reason:(AgoraChatCallEndReason)aReason time:(int)aTm type:(AgoraChatCallType)aType;
/**
 * \~chinese
 * 多人通话中的成员邀请其他用户时触发的回调。
 *
 * @param vc           当前通话页面的视图控制器。
 * @param users        发出邀请的通话成员及被邀请的用户 ID。
 * @param aExt         呼叫邀请中的扩展信息。
 *
 * \~english
 * Occurs when a participant in the multi-party call invites a user to join the call.
 *
 * @param vc           The view controller of the current call page.
 * @param users        The user IDs of the inviter and invitee.
 * @param aExt         The extension information in the call invitation.
 *
 */
- (void)multiCallDidInvitingWithCurVC:(UIViewController*_Nonnull)vc callType:(AgoraChatCallType)callType excludeUsers:(NSArray<NSString*> *_Nullable)users ext:(NSDictionary*_Nullable)aExt;
/**
 * \~chinese
 * 被叫振铃回调。
 *
 * @param aType         通话类型。详见 {@link AgoraChatCallDefine::AgoraChatCallType}。
 * @param user          主叫的 Chat 用户 ID。
 * @param aExt          呼叫邀请中的扩展信息。
 *
 * \~english
 * Occurs when the phone of the callee rings.
 *
 * @param aType         The call type. See {@link AgoraChatCallDefine::AgoraChatCallType}.
 * @param user          The Chat user ID of the caller.
 * @param aExt          The extension information in the call invitation.
 */
- (void)callDidReceive:(AgoraChatCallType)aType inviter:(NSString*_Nonnull)user ext:(NSDictionary*_Nullable)aExt;
/**
 * \~chinese
 * 通话异常回调。
 *
 * @param aError         错误信息。 详见 {@link AgoraChatCallError}。
 *
 * \~english
 * Occurs when an error is reported during a call.
 *
 * @param aError         The error information. See {@link AgoraChatCallError}.
 */
- (void)callDidOccurError:(AgoraChatCallError*_Nonnull)aError;
/**
 * \~chinese
 * 当前用户收到通话邀请或发起通话时触发的回调。
 *
 * 用户需在触发该回调后，从 App Server 获取声网 token，然后调用 `setRTCToken:channelName:` 方法传入该 token.
 *
 * @param aAppId        通话使用的 App ID。
 * @param aChannelName  通话的频道名称。
 * @param aUserAccount  用户使用的 Chat 用户 ID。
 *
 * \~english
 * Occurs when the current user receives a call invitation or starts a call.
 *
 * After this callback is triggered, the user needs to get the Agora token from the App Server and call the `setRTCToken:channelName:` method to pass the Agora token.
 *
 * @param aAppId        The App ID used by the call.
 * @param aChannelName  The channel name of the call.
 * @param aUserAccount  The Chat user ID of the user.
 */
- (void)callDidRequestRTCTokenForAppId:(NSString*_Nonnull)aAppId channelName:(NSString*_Nonnull)aChannelName account:(NSString*_Nonnull)aUserAccount uid:(NSInteger)aAgoraUid;
/**
 * \~chinese
 * 通话中对方加入其他通话时触发的回调。
 *
 * @param aChannelName  通话的频道名称。
 * @param aUid  用户声网ID。
 * @param aUserName  用户Chat SDK ID。
 *
 * \~english
 * Occurs when the peer user on call joins another call.
 *
 */
-(void)remoteUserDidJoinChannel:( NSString*_Nonnull)aChannelName uid:(NSInteger)aUid username:(NSString*_Nullable)aUserName;
/**
 * \~chinese
 * 通话中当前用户加入通话时触发的回调。
 *
 * \~english
 * Occurs when the current user on call joins call.
 *
 */
- (void)callDidJoinChannel:(NSString*_Nonnull)aChannelName uid:(NSUInteger)aUid;

@end

@interface AgoraChatCallManager : NSObject

+ (instancetype _Nonnull )alloc __attribute__((unavailable("call sharedManager instead")));
+ (instancetype _Nonnull )new __attribute__((unavailable("call sharedManager instead")));
- (instancetype _Nonnull )copy __attribute__((unavailable("call sharedManager instead")));
- (instancetype _Nonnull )mutableCopy __attribute__((unavailable("call sharedManager instead")));
+ (instancetype _Nonnull )sharedManager;

@property (nonatomic, strong, nullable) CXProvider *provider;
@property (nonatomic, strong, nullable) CXCallController *callController;

/**
 * \~chinese
 * 初始化 `EaseCall` 模块。
 *
 * @param aConfig      `EaseCall` 的配置，包括用户昵称、头像和呼叫超时时间等。
 * @param aDelegate    回调代理。
 *
 * \~english
 * Initializes the `EaseCall` module.
 *
 * @param aConfig      The settings of `EaseCall`, including the nickname and avatar of the user and the call timeout period.
 * @param aDelegate    The delegate.
 *
 */
- (void)initWithConfig:(AgoraChatCallConfig*_Nullable)aConfig delegate:(id<AgoraChatCallDelegate>_Nullable)aDelegate;
/**
 * \~chinese
 * 邀请用户进行一对一通话。
 *
 * @param uId                 受邀人的 Chat 用户 ID。
 * @param aType               通话类型：
 *                            - `EaseCallTypeAudio`：语音通话；
 *                            - `EaseCallTypeVideo`：视频通话。
 * @param aExt                通话邀请的扩展信息。
 * @param aCompletionBlock    该方法完成调用的回调：
 *                            - 成功返回通话 ID；
 *                            - 失败时返回错误信息。详见 {@link AgoraChatCallError}。
 *
 * \~english
 * Invites a user to join a one-to-one call.
 *
 * @param uId                 The Chat user ID of the invitee.
 * @param aType               The call type:
 *                            - `EaseCallTypeAudio`: The voice call.
 *                            - `EaseCallTypeVideo`: The video call.
 * @param aExt                The extension information in the call invitation.
 * @param aCompletionBlock    The completion block:
 *                            - If success, the call ID is returned.
 *                            - If a failure occurs, an error is returned. See {@link AgoraChatCallError}.
 *
 */
- (void)startSingleCallWithUId:(NSString*_Nonnull)uId type:(AgoraChatCallType)aType ext:(NSDictionary* _Nullable)aExt completion:(void (^_Nullable)(NSString* _Nullable callId,AgoraChatCallError* _Nullable aError))aCompletionBlock;
/**
 * \~chinese
 * 邀请用户进行多人通话。
 *
 * @param aUsers             受邀人的 Chat 用户 ID 数组。
 * @param aExt               通话邀请的扩展信息，如群组 ID 等信息。
 * @param aCompletionBlock   该方法完成调用的回调：
 *                           - 成功返回通话 ID；
 *                           - 失败时返回错误信息。详见 {@link AgoraChatCallError}。
 *
 * \~english
 * Invites users to join a multi-party call.
 *
 *  @param aUsers            The Chat user ID array of the invitees.
 * @param aExt               The extension information in the call invitation, such as the group ID.
 * @param aCompletionBlock   The completion block:
 *                           - If success, the call ID is returned.
 *                           - If a failure occurs, an error is returned. See {@link AgoraChatCallError}.
 */
- (void)startInviteUsers:(NSArray<NSString*>*_Nonnull)aUsers groupId:(NSString *)groupId callType:(AgoraChatCallType)callType ext:(NSDictionary*_Nullable)aExt  completion:(void (^_Nullable)(NSString*_Nullable callId,AgoraChatCallError*_Nullable aError))aCompletionBlock;

/**
 * \~chinese
 * 获取 `EaseCallKit` 的配置。
 *
 * @return  `EaseCallKit` 的配置。
 *
 * \~english
 *  Gets settings of `EaseCallKit`.
 *
 *  @return The settings of `EaseCallKit`.
 */
- (AgoraChatCallConfig*_Nonnull)getAgoraChatCallConfig;
/**
 * \~chinese
 * 设置声网频道及 token。
 *
 * @param aUid                      声网用户 ID。
 * @param aToken                    用户本次通话的声网 token。
 * @param aChannelName              用户要加入的频道名称。
 *
 * \~english
 * Sets the Agora channel and Agora token for the current user.
 *
 * @param aUid                      The Agora user ID.
 * @param aToken                    The Agora token for this call.
 * @param aChannelName              The name of the channel which the user joins.
 *
 */
- (void)setRTCToken:(NSString*_Nullable)aToken channelName:(NSString*_Nonnull)aChannelName uid:(NSUInteger)aUid;
/**
 * 设置用户的 Chat 用户 ID 与声网用户 ID 的映射表。
 *
 * @param aUsers         用户的 Chat 用户 ID 与声网用户 ID 的映射表。
 * @param aChannel       频道名称。
 *
 * \~english
 * Sets the mappings between Chat user IDs and Agora user IDs of users.
 *
 * @param aUsers         The mappings between Chat user IDs and Agora user IDs of users.
 * @param aChannel       The channel name.
 *
 */
- (void)setUsers:(NSDictionary<NSNumber*,NSString*>*_Nonnull)aUsers channelName:(NSString*_Nonnull)aChannel;

/**
 * \~chinese
 * 设置是否禁止本地用户发布视频流。
 *
 * @param mute 是否禁止本地用户发布视频流：
 *             - `YES`: 是；
 *             - `NO`: 否。
 *
 * \~english
 * Whether to prevent the current user from posting video streams.
 *
 * @param mute       Whether to prevent the current user from posting video streams:
 *                   - `YES`: Yes.
 *                   - `NO`: No.
 *
 */
- (int)muteLocalVideoStream:(BOOL)mute;

/**
 * \~chinese
 * 设置是否禁止接收远程用户的视频流。
 *
 * @param uid        远程用户声网 ID。
 * @param mute       是否禁止接收远程用户的视频流。
 *                   - `YES`: 是；
 *                   - `NO`: 否。
 * \~english
 * Whether to prevent receiving video streams of the remote user.
 *
 * @param uid        The Agora user ID of the remote user.
 * @param mute       Whether to prevent receiving video streams from the remote user:
 *                   - `YES`: Yes.
 *                   - `NO`: No.
 */
- (int)muteRemoteVideoStream:(NSUInteger)uid mute:(BOOL)mute;

/**
 * \~chinese
 * 清除所有通话相关的资源。
 *
 * \~english
 * Clears resources related to each call.
 *
 */
- (void)clearRes;

@end
