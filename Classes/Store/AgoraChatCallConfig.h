//
//  AgoraChatCallConfig.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/12/9.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import <Foundation/Foundation.h>
@import AgoraRtcKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  \~chinese
 *  用户的昵称和头像信息接口。
 *
 *  \~english
 *  The interface for the nickname and avatar of the user.
 */
@interface AgoraChatCallUser : NSObject
/**
 *  \~chinese
 *  用户昵称。
 *
 *  \~english
 *  The nickname of the user.
 */
@property (nonatomic,strong)  NSString* _Nullable  nickName;
/**
 *  \~chinese
 *  用户头像。
 *
 *  \~english
 *  The avatar of the user.
 */
@property (nonatomic,strong)  NSURL* _Nullable  headImage;

+ (instancetype)userWithNickName:(nullable NSString *)aNickName image:(nullable NSURL *)aUrl;

@end

/**
 *  \~chinese
 *  通话配置接口。
 *
 *  \~english
 *  The call configuration interface.
 */
@interface AgoraChatCallConfig : NSObject
/**
 *  \~chinese
 *  呼叫超时时间，即主叫发出通话邀请后等待被叫接听的最长时间。
 *
 *  单位为秒。默认为 30 秒。
 *
 *  \~english
 *  The call timeout period in seconds.
 *
 *  It indicates the maximum length of time that may elapse between the time when a call invitation is sent to wait for the callee to answer and the time when the call is ended.
 *
 *  The default value is 30 seconds.
 */
@property (nonatomic) UInt32 callTimeOut;
/**
 *  \~chinese
 *  用户信息字典。
 *
 *  字典中的数据为 key-value 格式，key 为用户 ID，value 为 `EaseCallUser`。
 *
 *  \~english
 *  The user information dictionary.
 *
 *  The dictionary contains key-value pairs, where the key is the user ID and the value is `EaseCallUser`.
 */
@property (nonatomic,strong) NSMutableDictionary<NSString*,AgoraChatCallUser*>* users;
/*
 * ringFileUrl    振铃文件
 */
@property (nonatomic,strong) NSURL* ringFileUrl;
/**
 *  \~chinese
 *  声网 App ID。
 *
 *  \~english
 *  The Agora App ID.
 */
@property (nonatomic,strong) NSString* agoraAppId;
/**
 *  \~chinese
 *  加入声网频道时是否开启声网 token 验证：
 *  - （默认） `YES`：开启。开启后必须实现 `callDidRequestRTCTokenForAppId` 回调，收到回调后调用 `setRTCToken` 传声网 token 才能发起或加入通话。
 *  - `NO`：关闭。
 *
 *  \~english
 *  Whether to enable Agora token authentication for the user attempting to join an Agora channel:
 *  - `YES`: Enables Agora token authentication. In this case, you must implement the `callDidRequestRTCTokenForAppId` callback. After receiving the callback, you need to call `setRTCToken` and pass the token before you make or join a call.
 *  - (Default) `NO`: Disables Agora token authentication.
 */
@property (nonatomic) BOOL enableRTCTokenValidate;
/**
 *  \~chinese
 *  声网 RTC 的视频编码器的配置。
 *
 *  \~english
 *  The configurations of the video encoder of Agora RTC.
 */
@property (nonatomic,strong) AgoraVideoEncoderConfiguration *encoderConfiguration;
@property (nonatomic) NSUInteger agoraUid;

@property (nonatomic, assign) BOOL enableIosCallKit;

/**
 *  \~chinese
 * 设置用户信息。
 *
 * @param aUser  用户 ID。
 * @param aInfo  用户信息。
 *
 *  \~english
 * Sets user information.
 *
 * @param aUser  The user ID.
 * @param aInfo  The user information.
 */
- (void)setUser:(NSString*)aUser info:(AgoraChatCallUser*)aInfo;

@end

NS_ASSUME_NONNULL_END
