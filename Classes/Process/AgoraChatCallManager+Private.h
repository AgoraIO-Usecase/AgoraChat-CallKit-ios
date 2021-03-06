//
//  AgoraChatCallManager+Private.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/12/3.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallManager.h"

@interface AgoraChatCallManager (Private)

- (void)switchCameraAction;
- (void)hangupAction;
- (void)acceptAction;
- (void)inviteAction;
- (void)muteAudio:(BOOL)muted;
- (void)speakeOut:(BOOL)enable;
- (BOOL)speakeOut;
- (NSString *)getNicknameByUserName:(NSString *)aUserName;
- (NSURL *)getHeadImageByUserName:(NSString *)aUserName;
- (NSString *)getUserNameByUid:(NSNumber *)uId;
- (void)startPreview;
- (void)setupLocalVideo:(UIView *)displayView;
- (void)setupRemoteVideoView:(NSUInteger)uid;
- (void)setupRemoteVideoView:(NSUInteger)uid withDisplayView:(UIView *)view;
- (void)joinChannel;
- (void)switchToVoice;
- (BOOL)checkCallIdCanHandle:(NSString *)callId;

@end /* AgoraChatCallManager_Private_h */
