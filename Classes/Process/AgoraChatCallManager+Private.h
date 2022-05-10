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
- (void)enableVideo:(BOOL)aEnable;
- (void)muteAudio:(BOOL)aMuted;
- (void)speakeOut:(BOOL)aEnable;
- (NSString *)getNicknameByUserName:(NSString *)aUserName;
- (NSURL *)getHeadImageByUserName:(NSString *)aUserName;
- (NSString *)getUserNameByUid:(NSNumber *)uId;
- (void)setupLocalVideo;
- (void)startPreview;
- (void)setupLocalVideo:(UIView *)displayView;
- (void)setupRemoteVideoView:(NSUInteger)uid;
- (void)setupRemoteVideoView:(NSUInteger)uid withDisplayView:(UIView *)view;
- (void)joinChannel;
- (void)switchToVoice;

@end /* AgoraChatCallManager_Private_h */
