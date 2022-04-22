//
//  EaseCallMultiViewController.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "EaseCallBaseViewController.h"
#import "EaseCallStreamView.h"

NS_ASSUME_NONNULL_BEGIN

@interface EaseCallMultiViewController : EaseCallBaseViewController

- (void)addMember:(NSNumber *)uId enableVideo:(BOOL)aEnableVideo;
- (void)removeRemoteViewForUser:(NSNumber *)uId;
- (void)setRemoteMute:(BOOL)aMuted uid:(NSNumber *)uId;
- (void)setRemoteEnableVideo:(BOOL)aEnabled uId:(NSNumber *)uId;
- (void)setLocalVideoView:(UIView *)localView enableVideo:(BOOL)aEnableVideo;
- (void)setRemoteViewNickname:(NSString *)aNickname headImage:(NSURL *)url uId:(NSNumber *)aUid;
- (void)setPlaceHolderUrl:(NSURL *)url member:(NSString *)uId;
- (void)removePlaceHolderForMember:(NSString *)uId;
- (void)setUser:(NSInteger)userId isTalking:(BOOL)isTalking;
- (NSArray<NSNumber *> *)getAllUserIds;

@property (nonatomic,strong) NSString *inviterId;
@property (nonatomic) EaseCallStreamView *localView;

- (EaseCallStreamView *)streamViewWithUid:(NSInteger)uid;

@end

NS_ASSUME_NONNULL_END
