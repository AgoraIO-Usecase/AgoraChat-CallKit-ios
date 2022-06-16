//
//  EaseCallMultiViewController.h
//  EMiOSDemo
//
//  Created by lixiaoming on 2020/11/19.
//  Copyright © 2020 lixiaoming. All rights reserved.
//

#import "AgoraChatCallBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface AgoraChatCallMultiViewController : AgoraChatCallBaseViewController

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCallType:(AgoraChatCallType)callType;
- (void)addMember:(NSNumber *)uId username:(NSString *)username enableVideo:(BOOL)aEnableVideo;
- (void)removeRemoteViewForUser:(NSNumber *)uId;
- (void)setRemoteMute:(BOOL)aMuted uid:(NSNumber *)uId;
- (void)setRemoteEnableVideo:(BOOL)aEnabled uId:(NSNumber *)uId;
- (void)setLocalVideoView:(UIView *)localView enableVideo:(BOOL)aEnableVideo;
- (void)setPlaceHolderUrl:(NSURL *)url member:(NSString *)uId;
- (void)removePlaceHolderForMember:(NSString *)uId;
- (void)setUser:(NSInteger)userId isTalking:(BOOL)isTalking;
- (NSArray<NSNumber *> *)getAllUserIds;

@property (nonatomic,strong) NSString *inviterId;

@end

NS_ASSUME_NONNULL_END
